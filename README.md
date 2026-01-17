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
```

# Phase 2: Shiny UI + Docker (API + UI)

## Phase 2 goal

Phase 2 extends the Phase 1 predictive API by adding:

* a **Shiny user interface** that consumes the API as a black-box service
* a **reproducible deployment** using **two interconnected Docker containers** (API + Shiny)

---

## Architecture (Phase 2)

* **API container (plumber, Phase 1):** runs `plumber.R` and loads the trained model from `model/model_logistic_DEATH_EVENT.rds`.
* **Shiny container (Phase 2):** runs `shiny/app.R` and calls the API over the Docker network.
* **Orchestration:** `docker-compose.yml` starts both services and connects them.

Environment variable used by the Shiny UI:

* `API_BASE_URL` (required): base URL used by the Shiny app to call the API.

  * Inside Docker: `http://api:8000`
  * Running Shiny locally: `http://127.0.0.1:8000`

---

## How to run (Docker)

From the repository root:

```bash
docker compose up -d --build
```

Then open:

* API: [http://localhost:8000](http://localhost:8000)
* Swagger: [http://localhost:8000/__docs__/](http://localhost:8000/__docs__/)
* Shiny UI: [http://localhost:3838/app](http://localhost:3838/app)

### Important notes

* From **your terminal/browser (host)**, `http://localhost:8000` works because Docker publishes the API port to the host.
* From **inside the Shiny container**, `localhost` means the Shiny container itself. To reach the API container, the UI must use the Docker Compose service name: `http://api:8000`.
* If you run `shiny/app.R` locally (outside Docker), the hostname `api` will not resolve. In that case set:

  * `API_BASE_URL=http://127.0.0.1:8000`

---

## Running from GitHub (Codespaces, no local Docker required)

If you cannot run Docker locally, you can execute the full system in **GitHub Codespaces** and access it via forwarded ports.

### 1) Create a Codespace

1. Open the repository on GitHub
2. Click **Code** → **Codespaces**
3. Click **Create codespace on main**
4. Wait for the browser-based VS Code environment to open

### 2) Start the system inside Codespaces

In the Codespaces terminal (repository root):

```bash
docker compose up -d --build
```

### 3) Forward ports and open the services

1. In the Codespaces VS Code UI, open the **Ports** tab
2. Ensure ports **8000** (API) and **3838** (Shiny) are listed

   * If they do not appear automatically, click **Add port / Forward a Port** and add `8000` and `3838`
3. Open the forwarded URLs from the Ports tab:

   * API health check: open the forwarded **8000** URL and append `/health`
   * Swagger: open the forwarded **8000** URL and append `/__docs__/`
   * Shiny UI: open the forwarded **3838** URL and append `/app`

### 4) Quick tests (inside Codespaces)

In a Codespaces terminal:

```bash
curl http://localhost:8000/health
curl -i -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d '{"age":60,"ejection_fraction":40,"serum_creatinine":1.2,"serum_sodium":135}'
```

### 5) Stop services and release resources

```bash
docker compose down
```

Stop or delete the Codespace from GitHub (**Your Codespaces**) when you are done to avoid consuming storage/compute resources.

---

## Quick API tests (Docker / Codespaces)

### Health check

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{"status":"ok"}
```

### Prediction

Use one of the following forms.

**Option A (one-line):**

```bash
curl -i -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d '{"age":60,"ejection_fraction":40,"serum_creatinine":1.2,"serum_sodium":135}'
```

**Option B (multi-line):**

```bash
curl -i -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age":60,"ejection_fraction":40,"serum_creatinine":1.2,"serum_sodium":135}'
```

Expected response fields:

* `probability` (numeric, 0–1)

---

## Phase 2 UI behavior

The Shiny UI:

* collects the required clinical inputs (`age`, `ejection_fraction`, `serum_creatinine`, `serum_sodium`) and performs basic client-side range validation
* checks API availability via `GET /health` and displays a live status indicator
* sends the inputs as JSON to `POST /predict` (the model runs only inside the API container)
* renders the returned death-risk probability (0–1) and a presentation-friendly percentage
* optionally displays the raw JSON response and allows downloading the latest prediction as a JSON file

The UI does not run the model locally and contains no predictive logic beyond input validation and result presentation.

---

## Phase 2 project structure

```text
.
├── api/
│   └── Dockerfile
├── shiny/
│   ├── app.R
│   └── Dockerfile
├── docker-compose.yml
├── plumber.R
├── model/
│   └── model_logistic_DEATH_EVENT.rds
└── README.md
```

---

## Help / Support

### 1) Docker build fails (R packages missing, e.g., plumber/httr)

If the containers start but logs show errors like:

* `there is no package called ‘plumber’`
* `there is no package called ‘httr’`

it usually means the R package install failed because **system (Linux) dependencies** were missing during the Docker build.

Ensure your Dockerfiles install the required OS dependencies before `install.packages()`, for example:

* `build-essential`
* `pkg-config`
* `libcurl4-openssl-dev`
* `libssl-dev`
* `libxml2-dev`
* `libsodium-dev` (needed by the R package `sodium`)
* `zlib1g-dev` (needed by packages that compile against zlib, e.g., `httpuv`)

After editing Dockerfiles, rebuild without cache:

```bash
docker compose down
docker compose build --no-cache api shiny
docker compose up -d
```

Check logs:

```bash
docker compose logs --tail=120 api
docker compose logs --tail=120 shiny
```

### 2) UI shows API unreachable

* Verify both containers are running:

```bash
docker compose ps -a
```

* Inside Docker, the UI must call the API using the service name `http://api:8000` (not `localhost`).

### 3) Hostname `api` cannot be resolved

This happens when running the Shiny app **outside Docker**.
Fix: run via Docker Compose, or set:

* `API_BASE_URL=http://127.0.0.1:8000`

### 4) Port already in use

If ports 8000 or 3838 are occupied on the host, stop the conflicting service or change the host ports in `docker-compose.yml` (e.g., `"8001:8000"`).

### 5) `curl` shows “Malformed input” / “Bad hostname”

This usually happens when line breaks are written incorrectly.
Use the one-line () or the multi-line `curl` commands shown above, making sure the `\` is the last character on each continued line.

### 6) Shiny fails to start after editing `app.R`

If the Shiny container exits immediately after you edit `app.R`, it is often due to an R parsing error (unbalanced quotes, especially inside long strings).
Check the logs to locate the exact line:

```bash
docker compose logs -f shiny
```

---

## Disclaimer

This project is for educational purposes only and does not replace clinical judgment.
