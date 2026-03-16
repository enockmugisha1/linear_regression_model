# Predicting Starting Salary from Education & Career Features

## Mission
Help students and career advisors understand which academic and career-related factors most influence starting salary after graduation, enabling better decision-making around internships, GPA, certifications, and skill development.

## Dataset
- **Source:** [Kaggle — Education & Career Success Dataset](https://www.kaggle.com/datasets/adilshamim8/education-and-career-success)
- **Size:** 400 rows × 19 columns
- **Features include:** GPA, SAT Score, Internships, Certifications, Soft Skills, Networking Score, Field of Study, and more
- **Target variable:** `Starting_Salary`

## Project Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb        # Main notebook with all models
│   ├── API/                          # (Leave empty for now)
│   └── FlutterApp/                   # (Leave empty for now)
│
└── README.md
```

## Models Implemented
| Model | Train MSE | Test MSE | R² Score |
|---|---|---|---|
| Linear Regression | 19,594,473 | 17,593,758 | 0.9813 |
| Decision Tree | 4,845,100 | 8,365,615 | 0.9911 |
| **Random Forest** ✅ | **906,579** | **5,007,462** | **0.9947** |

> ✅ **Best Model: Random Forest** — saved as `best_model.joblib`

## How to Run

1. Clone the repo:
```bash
git clone https://github.com/YOUR_USERNAME/linear_regression_model.git
cd linear_regression_model
```

2. Install dependencies:
```bash
pip install pandas numpy matplotlib seaborn scikit-learn joblib
```

3. Open the notebook:
```bash
jupyter notebook summative/linear_regression/multivariate.ipynb
```

## Key Findings
- **University GPA**, **Internships Completed**, and **Job Offers** are the strongest predictors of starting salary
- Random Forest outperformed all models with the lowest test MSE and highest R² score
- The loss curve confirms the SGD model converges well without significant overfitting
