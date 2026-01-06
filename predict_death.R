library(tidyverse)
library(caret)
library(broom)
library(pROC)

# =========================================================
# 1. Cargar datos
# =========================================================

df <- read.csv("heart_failure_clinical_records_dataset.csv")

# Asegurar que DEATH_EVENT es binaria 0/1 numérica
df$DEATH_EVENT <- as.integer(as.character(df$DEATH_EVENT))
stopifnot(all(df$DEATH_EVENT %in% c(0, 1)))

# =========================================================
# 2. División train / test
# =========================================================

set.seed(123)
train_index <- createDataPartition(df$DEATH_EVENT, p = 0.8, list = FALSE)

train <- df[train_index, , drop = FALSE]
test  <- df[-train_index, , drop = FALSE]

# =========================================================
# 3. Modelo logístico final
# =========================================================

model_logistic <- glm(
  DEATH_EVENT ~ serum_creatinine + ejection_fraction + age + I(age^2),
  data = train,
  family = binomial(link = "logit")
)

summary(model_logistic)

# Odds ratios e IC95%
# (age y age^2 se interpretan conjuntamente)
tidy(model_logistic, exponentiate = TRUE, conf.int = TRUE)

# =========================================================
# 4. Predicción
# =========================================================

probs <- predict(model_logistic, newdata = test, type = "response")
pred_class <- ifelse(probs >= 0.5, 1, 0)

# =========================================================
# 5. Métricas
# =========================================================

pred_factor <- factor(pred_class, levels = c(0, 1))
true_factor <- factor(test$DEATH_EVENT, levels = c(0, 1))

confusionMatrix(pred_factor, true_factor)

roc_obj <- roc(response = test$DEATH_EVENT, predictor = probs, quiet = TRUE)
auc(roc_obj)

# =========================================================
# 6. Guardar modelo
# =========================================================

saveRDS(model_logistic,"model/model_logistic_DEATH_EVENT.rds")
