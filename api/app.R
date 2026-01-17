library(shiny)
library(httr)
library(jsonlite)

# ---------------------------------------------------------
# Config (Docker: http://api:8000 ; Local: http://127.0.0.1:8000)
# ---------------------------------------------------------
API_BASE_URL <- Sys.getenv("API_BASE_URL", "http://api:8000")
PREDICT_PATH <- "/predict"
HEALTH_PATH  <- "/health"

api_url <- function(path) paste0(API_BASE_URL, path)

# ---------------------------------------------------------
# UI
# ---------------------------------------------------------
ui <- fluidPage(
  titlePanel("Heart Failure Mortality Prediction"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Inputs (must match API contract)"),
      
      numericInput("age", "Age (years)", value = 60, min = 0, max = 120),
      numericInput("ejection_fraction", "Ejection fraction (%)", value = 40, min = 0, max = 100),
      numericInput("serum_creatinine", "Serum creatinine (mg/dL)", value = 1.2, min = 0.01, max = 20),
      numericInput("serum_sodium", "Serum sodium (mEq/L)", value = 135, min = 90, max = 200),
      
      actionButton("btn_predict", "Predict"),
      
      tags$hr(),
      strong("API status: "),
      textOutput("api_status", inline = TRUE)
    ),
    
    mainPanel(
      h4("Result"),
      verbatimTextOutput("result_box"),
      tags$hr(),
      p("Disclaimer: Educational use only. This does not replace clinical judgment.")
    )
  )
)

# ---------------------------------------------------------
# Server
# ---------------------------------------------------------
server <- function(input, output, session) {
  
  output$api_status <- renderText({
    tryCatch({
      r <- GET(api_url(HEALTH_PATH), timeout(2))
      if (status_code(r) == 200) "OK" else paste("ERROR", status_code(r))
    }, error = function(e) {
      "UNREACHABLE"
    })
  })
  
  observeEvent(input$btn_predict, {
    
    # Build request payload exactly as required by plumber.R
    payload <- list(
      age = input$age,
      ejection_fraction = input$ejection_fraction,
      serum_creatinine = input$serum_creatinine,
      serum_sodium = input$serum_sodium
    )
    
    output$result_box <- renderText("Calling API...")
    
    res <- tryCatch({
      POST(
        url = api_url(PREDICT_PATH),
        body = payload,
        encode = "json",
        timeout(10)
      )
    }, error = function(e) e)
    
    if (inherits(res, "error")) {
      output$result_box <- renderText(paste("API call failed:", res$message))
      return()
    }
    
    # Non-200: show error body if present (plumber returns {"error":"..."} with status 400)
    if (status_code(res) != 200) {
      txt <- tryCatch(content(res, as = "text", encoding = "UTF-8"), error = function(e) "")
      output$result_box <- renderText(paste("API error", status_code(res), "\n", txt))
      return()
    }
    
    out <- tryCatch(content(res, as = "parsed", type = "application/json"), error = function(e) NULL)
    if (is.null(out)) {
      output$result_box <- renderText("API response could not be parsed as JSON.")
      return()
    }
    
    prob <- out$probability
    
    output$result_box <- renderText({
      paste0(
        "Probability: ", ifelse(is.null(prob), "N/A", round(as.numeric(prob), 4)), "\n",
        "Raw JSON:\n", toJSON(out, auto_unbox = TRUE, pretty = TRUE)
      )
    })
  })
}

shinyApp(ui, server)
