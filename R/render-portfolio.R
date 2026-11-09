#' @title Render Portfolio
#' @description Render portfolio.
#' @export
#' @param  site_number Optional. A USGS stream gage number. Explore stream gages on NWIS
#' \link{https://maps.waterdata.usgs.gov/mapper/index.html}. If \code{NULL}, a random
#' eligible site is selected. Do not provide if state is specified.
#' @param state Optional. A two letter abbreviation for a US state, e.g. \code{"CO"}.
#' Only provide if \code{site_number} is not given.
#' @param start_date Optional. Provide as \code{"YYYY-mm_dd"}, otherwise 1 month
#' prior to today will be used.
#' @param end_date Optional. Provide as \code{"YYYY-mm-dd"}, otherwise today will be used.
#' @param shiny Logical. Should the portfolio be rendered as an R Shiny app?
#' Default is \code{FALSE} which renders the portfolio in Rmarkdown format.
#' @returns Portfolio in Rmarkdown or Shiny format.
#' 
render_portfolio <- function(site_number = NULL,
                             state = NULL,
                             start_date = NULL,
                             end_date = NULL,
                             shiny = FALSE) {

  # If start and end dates are not provided, default to the past month of data
  if (is.null(start_date)) start_date <- Sys.Date() - 30
  if (is.null(end_date)) end_date <- Sys.Date()
  
  # Stop if site number and state are provided
  if (!is.null(state) && !is.null(site_number)) stop("Provide state OR site number, not both.")
  
  # If site number is not provided, get random eligible site
  if (is.null(site_number)) {
    state <- ifelse(is.null(state),
                    sample(state.abb, 1),
                    state)
    ansi_codes <- read.table(
      file = "https://www2.census.gov/geo/docs/reference/state.txt",
      sep = "|",
      header = TRUE,
      stringsAsFactors = FALSE,
      strip.white = TRUE)
    
    state_code <- ansi_codes %>%
      subset(STUSAB == state) %>%
      dplyr::pull(STATE) %>%
      stringr::str_pad(., width = 2, pad = "0")
    
    # Query sites with flow data
    flow_sites <-
      dataRetrieval::read_waterdata_combined_meta(
        state_code = state_code,
        parameter_code = "00060",
        computation_identifier = "Instantaneous",
        site_type = "Stream") %>%
      sf::st_drop_geometry() %>%
      dplyr::filter(as.Date(begin) <= end_date & as.Date(end) >= start_date)
    
    # Query sites with stage data
    stage_sites <-
      dataRetrieval::read_waterdata_combined_meta(
        state_code = state_code,
        parameter_code = "00065",
        computation_identifier = "Instantaneous",
        site_type = "Stream") %>%
      sf::st_drop_geometry() %>%
      dplyr::filter(as.Date(begin) <= end_date & as.Date(end) >= start_date)
    
    # Select random site
    # Otherwise, use user provided site number(s)
    site <- sample(intersect(flow_sites$monitoring_location_id, stage_sites$monitoring_location_id), 
                   ifelse(isTRUE(shiny), 3, 1))
  } else {
    site <- site_number
  }
  
  # Render shiny portfolio
  if (isTRUE(shiny)) {
    rmarkdown::run(
      file = here::here("inst", "rmd", "shiny-portfolio.Rmd"),
      render_args = list(params = list(
        site_number = site,
        start_date = start_date,
        end_date = end_date
      )))
  } else {
    # Check that only one stream gage is provided
    if (length(site) > 1) stop("Invalid parameters. Either set shiny = TRUE or provide only ONE gage station.")
    # Render Rmarkdown portfolio
    rmarkdown::render(
      input = here::here("inst", "rmd", "portfolio.Rmd"),
      output_dir = here::here("inst", "output"),
      output_file = paste0("portfolio-",
                           site,
                           ".html"),
      params = list(
        site_number = site,
        start_date = start_date,
        end_date = end_date
      ),
      envir = parent.frame()
    )
  }
}
