# Heart Failure Mortality Prediction API

This project builds a logistic regression model to predict the probability of death in patients with heart failure and exposes the model through a REST API using plumber in R.

The workflow follows three main steps:
Exploratory Data Analysis → Model Training → API Deployment

---

## Workflow Description

### 1. Exploratory Data Analysis (EDA.R)

This script explores the dataset to understand variable distributions and their relationship with mortality.

Main actions:
- Load the dataset
- Convert binary variables to categorical factors
- Generate summary statistics
- Visualize correlations and distributions

The EDA helps justify the selection of variables used in the predictive model.

---

### 2. Model Training (predict_death.R)

This script trains the predictive model.

Main actions:
- Load and clean the dataset
- Ensure the outcome variable (DEATH_EVENT) is binary
- Split the data into training (80%) and test (20%) sets
- Train a logistic regression model
- Select informative variables
- Save the trained model to disk

The output is a trained logistic regression model stored as an `.rds` file.

---

### 3. API Deployment (plumber.R)

This script exposes the trained model as a REST API.

Endpoints:
- `GET /health` — API status check
- `POST /predict` — Predict mortality probability

Features:
- Accepts only the variables used by the model
- Validates input values
- Returns predictions in JSON format
- Automatically generates Swagger documentation

---

## How to Run the Project

1. Clone the repository.
2. Open the project in RStudio.
3. Run the exploratory analysis:
```r
source("EDA.R")
```
4. Train the model:
```r
source("predict_death.R")
```
5. Run the API:
```r
plumber::plumb("plumber.R")$run()
```
6. Open Swagger UI in your browser:
```perl
http://127.0.0.1:<PORT>/__docs__/

