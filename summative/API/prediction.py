import os
import io
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
import joblib

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score

import uvicorn

# ── Paths ──────────────────────────────────────────────────────────────────────
MODEL_PATH = "best_model.joblib"
SCALER_PATH = "scaler.joblib"
DATA_URL = (
    "https://raw.githubusercontent.com/enockmugisha1/"
    "linear_regression_model/main/education_career_success%20(1).csv"
)

FEATURE_COLUMNS = [
    "Age", "Gender", "High_School_GPA", "SAT_Score", "University_GPA",
    "Field_of_Study", "Internships_Completed", "Projects_Completed",
    "Certifications", "Soft_Skills_Score", "Networking_Score", "Job_Offers",
    "Career_Satisfaction", "Years_to_Promotion", "Current_Job_Level",
    "Work_Life_Balance", "Entrepreneurship",
]


# ── Training helper ────────────────────────────────────────────────────────────
def train_and_save(df: pd.DataFrame | None = None) -> dict:
    """Train Linear Regression, Decision Tree, and Random Forest.
    Save the best (lowest test MSE) model + scaler to disk."""

    if df is None:
        df = pd.read_csv(DATA_URL)

    df = df.drop(columns=["Student_ID"], errors="ignore").copy()

    # Encode categoricals that are still non-numeric
    le = LabelEncoder()
    encoded = {}
    for col in ["Gender", "Field_of_Study", "Current_Job_Level", "Entrepreneurship"]:
        if col in df.columns and not pd.api.types.is_numeric_dtype(df[col]):
            encoded[col] = le.fit_transform(df[col].astype(str).values)
    for col, vals in encoded.items():
        df = df.assign(**{col: vals})

    X = df[FEATURE_COLUMNS]
    y = df["Starting_Salary"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc = scaler.transform(X_test)

    # --- three required models ---
    lr = LinearRegression()
    lr.fit(X_train_sc, y_train)
    lr_mse = mean_squared_error(y_test, lr.predict(X_test_sc))
    lr_r2 = r2_score(y_test, lr.predict(X_test_sc))

    dt = DecisionTreeRegressor(max_depth=5, random_state=42)
    dt.fit(X_train_sc, y_train)
    dt_mse = mean_squared_error(y_test, dt.predict(X_test_sc))
    dt_r2 = r2_score(y_test, dt.predict(X_test_sc))

    rf = RandomForestRegressor(n_estimators=100, random_state=42)
    rf.fit(X_train_sc, y_train)
    rf_mse = mean_squared_error(y_test, rf.predict(X_test_sc))
    rf_r2 = r2_score(y_test, rf.predict(X_test_sc))

    candidates = {
        "LinearRegression": (lr, lr_mse, lr_r2),
        "DecisionTree": (dt, dt_mse, dt_r2),
        "RandomForest": (rf, rf_mse, rf_r2),
    }

    best_name = min(candidates, key=lambda k: candidates[k][1])
    best_model_obj = candidates[best_name][0]

    joblib.dump(best_model_obj, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    return {
        "best_model": best_name,
        "metrics": {
            name: {"test_mse": round(vals[1], 2), "r2": round(vals[2], 4)}
            for name, vals in candidates.items()
        },
    }


# ── Bootstrap: train if model files are missing ────────────────────────────────
if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
    print("Model files not found — training now …")
    train_and_save()
    print("Training complete.")


# ── App ────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Starting Salary Predictor API",
    description=(
        "Predicts a graduate's starting salary from education and career features. "
        "Dataset: Kaggle Education & Career Success."
    ),
    version="1.0.0",
)

# CORS — explicit origins (not wildcard) to satisfy assignment rubric
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://10.0.2.2",          # Android emulator → host machine
        "http://10.0.2.2:8000",
        "https://linear-regression-api.onrender.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
)


# ── Pydantic input model ───────────────────────────────────────────────────────
class PredictionInput(BaseModel):
    age: int = Field(..., ge=18, le=65, description="Age of the student (18–65)")
    gender: int = Field(..., ge=0, le=1, description="Gender — 0: Female, 1: Male")
    high_school_gpa: float = Field(..., ge=0.0, le=4.0, description="High school GPA (0.0–4.0)")
    sat_score: int = Field(..., ge=400, le=1600, description="SAT score (400–1600)")
    university_gpa: float = Field(..., ge=0.0, le=4.0, description="University GPA (0.0–4.0)")
    field_of_study: int = Field(..., ge=0, le=10, description="Encoded field of study (0–10)")
    internships_completed: int = Field(..., ge=0, le=10, description="Internships completed (0–10)")
    projects_completed: int = Field(..., ge=0, le=20, description="Projects completed (0–20)")
    certifications: int = Field(..., ge=0, le=10, description="Certifications earned (0–10)")
    soft_skills_score: int = Field(..., ge=1, le=10, description="Soft skills score (1–10)")
    networking_score: int = Field(..., ge=1, le=10, description="Networking score (1–10)")
    job_offers: int = Field(..., ge=0, le=10, description="Job offers received (0–10)")
    career_satisfaction: int = Field(..., ge=1, le=10, description="Career satisfaction (1–10)")
    years_to_promotion: int = Field(..., ge=0, le=10, description="Years to first promotion (0–10)")
    current_job_level: int = Field(..., ge=0, le=4, description="Encoded current job level (0–4)")
    work_life_balance: int = Field(..., ge=1, le=10, description="Work-life balance score (1–10)")
    entrepreneurship: int = Field(..., ge=0, le=1, description="Entrepreneurship — 0: No, 1: Yes")

    model_config = {
        "json_schema_extra": {
            "example": {
                "age": 25,
                "gender": 0,
                "high_school_gpa": 3.5,
                "sat_score": 1280,
                "university_gpa": 3.2,
                "field_of_study": 6,
                "internships_completed": 2,
                "projects_completed": 6,
                "certifications": 2,
                "soft_skills_score": 7,
                "networking_score": 6,
                "job_offers": 2,
                "career_satisfaction": 7,
                "years_to_promotion": 4,
                "current_job_level": 1,
                "work_life_balance": 7,
                "entrepreneurship": 0,
            }
        }
    }


# ── Endpoints ──────────────────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
def root():
    return {
        "message": "Starting Salary Predictor API is running",
        "docs": "/docs",
        "predict": "/predict",
        "retrain": "/retrain",
    }


@app.post("/predict", tags=["Prediction"])
def predict(data: PredictionInput):
    """Return a predicted starting salary (USD) for the provided student profile."""
    try:
        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)

        features = np.array([[
            data.age, data.gender, data.high_school_gpa, data.sat_score,
            data.university_gpa, data.field_of_study, data.internships_completed,
            data.projects_completed, data.certifications, data.soft_skills_score,
            data.networking_score, data.job_offers, data.career_satisfaction,
            data.years_to_promotion, data.current_job_level, data.work_life_balance,
            data.entrepreneurship,
        ]])

        prediction = model.predict(scaler.transform(features))[0]
        return {
            "predicted_starting_salary": round(float(prediction), 2),
            "currency": "USD",
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@app.post("/retrain", tags=["Retraining"])
async def retrain(file: UploadFile = File(...)):
    """Upload a new CSV file to retrain all three models and update the saved best model."""
    try:
        contents = await file.read()
        df = pd.read_csv(io.BytesIO(contents))

        required = set(FEATURE_COLUMNS + ["Starting_Salary"])
        missing = required - set(df.columns)
        if missing:
            raise HTTPException(
                status_code=422,
                detail=f"Uploaded CSV is missing columns: {sorted(missing)}",
            )

        result = train_and_save(df)
        return {"message": "Model retrained successfully", **result}

    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


# ── Entry point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run("prediction:app", host="0.0.0.0", port=8000, reload=True)
