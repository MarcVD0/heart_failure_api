library(tidyverse)
library(caret)
library(ggplot2)
library(ggcorrplot)

df <- read.csv("heart_failure_clinical_records_dataset.csv")

# variables binarias como factor
cat_vars <- c("anaemia","diabetes","high_blood_pressure","sex","smoking","DEATH_EVENT")
df[cat_vars] <- lapply(df[cat_vars], factor)

# Descripcion general del dataset
summary(df)
str(df)
table(df$DEATH_EVENT)

#Histogramas de variables continuas
cont_vars <- c("age","creatinine_phosphokinase","ejection_fraction",
               "platelets","serum_creatinine","serum_sodium")

df %>%
  pivot_longer(all_of(cont_vars)) %>%
  ggplot(aes(value)) +
  geom_histogram(fill="steelblue", color="black") +
  facet_wrap(~name, scales="free") +
  theme_minimal()

#Boxplots por DEATH_EVENT
df %>%
  pivot_longer(all_of(cont_vars)) %>%
  ggplot(aes(x = DEATH_EVENT, y = value, fill = DEATH_EVENT)) +
  geom_boxplot() +
  facet_wrap(~name, scales="free") +
  theme_minimal()

#Correlacion de variables numericas
corr <- cor(df[, sapply(df, is.numeric)])
ggcorrplot(corr, lab = TRUE)

#Comparacion con tablas
aggregate(. ~ DEATH_EVENT, data=df[, c("DEATH_EVENT","age","ejection_fraction","serum_creatinine")], mean)

