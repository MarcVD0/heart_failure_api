library(plumber)

#* @apiTitle Heart Failure Mortality Prediction API
#* @apiDescription This API provides a logistic regression prediction of the probability of death in patients with heart failure, using clinical variables from the Heart Failure Clinical Records dataset.


#load model
model <- readRDS("../model/model_logistic_DEATH_EVENT.rds")

#* Health check endpoint
#* @tag System
#* @get /health
#* @serializer json
function() {
  list(status = "ok")
}

#* Predict probability of heart failure
#* @tag Prediction
#*
#* Returns the predicted probability that DEATH_EVENT = 1
#*
#* @param age Numeric. Patient age.
#* @param anaemia Integer (0/1).
#* @param creatinine_phosphokinase Numeric.
#* @param diabetes Integer (0/1).
#* @param ejection_fraction Numeric.
#* @param high_blood_pressure Integer (0/1).
#* @param platelets Numeric.
#* @param serum_creatinine Numeric.
#* @param serum_sodium Numeric.
#* @param sex Integer (0/1).
#* @param smoking Integer (0/1).
#* @post /predict
#* @serializer json
function(age,
         anaemia,
         creatinine_phosphokinase,
         diabetes,
         ejection_fraction,
         high_blood_pressure,
         platelets,
         serum_creatinine,
         serum_sodium,
         sex,
         smoking) {
  
  input <- data.frame(
    age = as.numeric(age),
    anaemia = factor(as.integer(anaemia), levels = c(0, 1)),
    creatinine_phosphokinase = as.numeric(creatinine_phosphokinase),
    diabetes = factor(as.integer(diabetes), levels = c(0, 1)),
    ejection_fraction = as.numeric(ejection_fraction),
    high_blood_pressure = factor(as.integer(high_blood_pressure), levels = c(0, 1)),
    platelets = as.numeric(platelets),
    serum_creatinine = as.numeric(serum_creatinine),
    serum_sodium = as.numeric(serum_sodium),
    sex = factor(as.integer(sex), levels = c(0, 1)),
    smoking = factor(as.integer(smoking), levels = c(0, 1))
  )
  
  prob <- as.numeric(predict(model, newdata = input, type = "response"))
  
  list(probability = prob)
}
