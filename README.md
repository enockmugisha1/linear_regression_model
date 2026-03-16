# Predicting Graduate Starting Salary from Education & Career Factors

## Mission
Many students graduate without knowing which academic and career choices actually drive earning potential. This project builds a machine learning model to predict a student's starting salary based on features like GPA, internships, certifications, and field of study — giving students and advisors data-driven guidance on what matters most.

## Dataset
- **Source:** [Kaggle — Education & Career Success Dataset](https://www.kaggle.com/datasets/adilshamim8/education-and-career-success)
- **Size:** 400 rows × 19 columns — includes GPA, SAT Score, Internships, Certifications, Soft Skills, Networking Score, Field of Study, Job Offers, and more
- **Target variable:** `Starting_Salary`

## Project Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb        # Main notebook: EDA, feature engineering, all models, predictions
│   ├── API/                          # (Leave empty for now)
│   └── FlutterApp/                   # (Leave empty for now)
│
└── README.md
```

## Models & Results

| Model | Train MSE | Test MSE | R² Score |
|---|---|---|---|
| Linear Regression | 19,594,473 | 17,593,758 | 0.9813 |
| Decision Tree | 4,845,100 | 8,365,615 | 0.9911 |
| **Random Forest** ✅ | **906,579** | **5,007,462** | **0.9947** |

**Best Model: Random Forest** — saved as `best_model.joblib`

## Key Findings
- **University GPA**, **Internships Completed**, and **Job Offers** are the strongest predictors of starting salary
- Random Forest outperformed all other models with the lowest test MSE and highest R² (0.9947)
- The SGD loss curve confirms gradient descent converges well with no significant overfitting
- A student with high GPA + 4 internships can expect ~$120K vs ~$48K for low GPA + 1 internship

## How to Run

```bash
git clone https://github.com/enockmugisha1/linear_regression_model.git
cd linear_regression_model
pip install pandas numpy matplotlib seaborn scikit-learn joblib
jupyter notebook summative/linear_regression/multivariate.ipynb
```
