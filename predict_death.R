library(tidyverse)
library(caret)
library(broom)
library(pROC)

#1 - CARREGAR DADES
df <- read.csv("heart_failure_clinical_records_dataset.csv")


#assegurar que DEATH_EVENT es binaria 0/1 numérica
df$DEATH_EVENT <- as.integer(as.character(df$DEATH_EVENT))
stopifnot(all(df$DEATH_EVENT %in% c(0, 1)))


#2 - DIVISION TRAINING/TEST
set.seed(123)
train_index <- createDataPartition(df$DEATH_EVENT, p = 0.8, list = FALSE)

train <- df[train_index, , drop = FALSE]
test  <- df[-train_index, , drop = FALSE]

# 3.0 - Variable selection (scope and step functions)
full_model <- glm(
  DEATH_EVENT ~ age + sex + anaemia + diabetes + high_blood_pressure + smoking +
    creatinine_phosphokinase + ejection_fraction + platelets + serum_creatinine + serum_sodium,
  data = train,
  family = binomial(link = "logit")
)

scope <- list(
  lower = DEATH_EVENT ~ 1,
  upper = formula(full_model)
)

model_logistic_variables <- step(full_model, scope = scope, direction = "both", trace = 0)

cat("Final model formula:\n")
print(formula(model_logistic_variables))


#4 - Modelo logístico final
#Age was modeled using both linear and quadratic terms to capture non-linear increases in mortality risk.
model_logistic <- glm(
  DEATH_EVENT ~ age + ejection_fraction + serum_creatinine + serum_sodium + I(age^2),
  data = train,
  family = binomial(link = "logit")
)

summary(model_logistic)

# Odds ratios e IC95%
#converteix model logistic (log-odds) en taula interpretable (odds ratio + IC95)
# (age y age^2 se interpretan conjuntamente)
tidy(model_logistic, exponentiate = TRUE, conf.int = TRUE)

# Predicted probabilities para pacientest test
probs <- predict(model_logistic, newdata = test, type = "response")

# True labels as numeric 0/1
#lo que realmente pasó con cada paciente: 0=muere, 1=sobrevive
y_true <- test$DEATH_EVENT
if (is.factor(y_true)) {
  y_true <- as.integer(as.character(y_true))
}

# ROC object (needed for Youden) - curve
#¿El modelo da mayor probabilidad a los que mueren que a los que sobreviven?
roc_obj <- roc(
  response = y_true,
  predictor = probs,
  levels = c(0, 1),
  direction = "<",
  quiet = TRUE
)

# AUC (model quality, threshold-free) - area of the curve
#¿Qué tan bueno es ese ordenamiento de riesgo?
auc(roc_obj)

# Youden threshold (best balance sensitivity/specificity)
best_thresh <- coords(
  roc_obj,
  "best",
  ret = "threshold",
  best.method = "youden"
)

# Predictions using default threshold 0.5 (baseline)
pred_05 <- ifelse(probs >= 0.5, 1, 0)

# Predictions using Youden threshold
best_thresh <- as.numeric(best_thresh)
pred_youden <- ifelse(probs >= best_thresh, 1, 0)

# Confusion matrix @ 0.5
confusionMatrix(
  factor(pred_05, levels = c(0, 1)),
  factor(y_true, levels = c(0, 1)),
  positive = "1"
)

# Confusion matrix @ Youden
confusionMatrix(
  factor(pred_youden, levels = c(0, 1)),
  factor(y_true, levels = c(0, 1)),
  positive = "1"
)


#saving model and variables
model_vars <- setdiff(all.vars(formula(model_logistic_variables)), "DEATH_EVENT")

saveRDS(model_logistic, "model/model_logistic_DEATH_EVENT.rds")
saveRDS(model_vars, "model/model_vars.rds")
