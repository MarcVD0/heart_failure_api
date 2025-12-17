library(tidyverse)
library(caret)
library(broom)
library(pROC)

# 1. Cargar datos ------------------------------------------------------------

df <- read.csv("data/heart_failure_clinical_records_dataset.csv")

# Convertir predictores binarios a factor
cat_vars <- c("anaemia", "diabetes", "high_blood_pressure",
              "sex", "smoking", "DEATH_EVENT")
df[cat_vars] <- lapply(df[cat_vars], factor)

# 2. División train / test ---------------------------------------------------

set.seed(123)

train_index <- createDataPartition(df$DEATH_EVENT, p = 0.8, list = FALSE)
train <- df[train_index, ]
test  <- df[-train_index, ]

# 3. Modelo logístico --------------------------------------------------------

model_logistic <- glm(
  DEATH_EVENT ~ age +
    anaemia +
    creatinine_phosphokinase +
    diabetes +
    ejection_fraction +
    high_blood_pressure +
    platelets +
    serum_creatinine +
    serum_sodium +
    sex +
    smoking,
  data = train,
  family = binomial(link = "logit")
)

summary(model_logistic)
tidy(model_logistic, exponentiate = TRUE, conf.int = TRUE)

# 4. Predicción --------------------------------------------------------------

probs <- predict(model_logistic, newdata = test, type = "response")
pred_class <- ifelse(probs > 0.5, 1, 0)

# 5. Métricas ----------------------------------------------------------------

confusionMatrix(
  factor(pred_class, levels = c(0,1)),
  test$DEATH_EVENT
)

roc_obj <- roc(test$DEATH_EVENT, probs)
auc(roc_obj)

# 6. Guardar el modelo -------------------------------------------------------

saveRDS(model_logistic,
        "model/model_logistic_DEATH_EVENT.rds")