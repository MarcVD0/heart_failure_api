FROM rocker/shiny:4.3.1

RUN R -e "install.packages(c('httr','jsonlite'), repos='https://cloud.r-project.org')"

WORKDIR /srv/shiny-server/app
COPY shiny/app.R ./app.R

EXPOSE 3838

