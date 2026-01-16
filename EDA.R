library(tidyverse)
library(caret)
library(ggplot2)
library(ggcorrplot)

df <- read.csv("heart_failure_clinical_records_dataset.csv")

# variables binarias como categoricas
cat_vars <- c("anaemia","diabetes","high_blood_pressure","sex","smoking","DEATH_EVENT")
df[cat_vars] <- lapply(df[cat_vars], factor)

# Descripcion general del dataset
summary(df)
str(df) #que variables y como estan codificadas
table(df$DEATH_EVENT)

#variables continuas
cont_vars <- c("age","creatinine_phosphokinase","ejection_fraction",
               "platelets","serum_creatinine","serum_sodium")
# Histograms
print(
  df %>%
    pivot_longer(all_of(cont_vars)) %>%
    ggplot(aes(value)) +
    geom_histogram(fill="steelblue", color="black") +
    facet_wrap(~name, scales="free") +
    theme_minimal()
)

# Boxplots
print(
  df %>%
    pivot_longer(all_of(cont_vars)) %>%
    ggplot(aes(x = DEATH_EVENT, y = value, fill = DEATH_EVENT)) +
    geom_boxplot() +
    facet_wrap(~name, scales="free") +
    theme_minimal()
)

# Correlation plot
corr <- cor(df[, sapply(df, is.numeric)])
print(ggcorrplot(corr, lab = TRUE))

#Comparacion con tablas
aggregate(. ~ DEATH_EVENT, data=df[, c("DEATH_EVENT","age","ejection_fraction","serum_creatinine")], mean)

