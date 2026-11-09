#' @title Fetch Flow Data from USGS Stream Gage
#' @description Fetch flow data from USGS stream gage
#' @export
#' @param site_number USGS stream gage site number.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return A list of data frames. \code{site_data} is the time series flow and gage height data. 
#' \code{site_metadata} is the metadata associated with the requested gage station.
#'
fetch_gage_data <- function(site_number, start_date, end_date) {
  # Initiate data frames for appending
  site_data <- c()
  site_metadata <- c()
  for (i in site_number) {
    # Confirm that station(s) provided collects flow and stage data
    query <- dataRetrieval::read_waterdata_combined_meta(monitoring_location_id = i)
    sufficient_data <- ifelse(
      any(query$site_type_code == "ST") &&
        any(query$parameter_code == "00065") &&
        any(query$parameter_code == "00060"),
      TRUE,
      FALSE
    )
    
    if (isFALSE(sufficient_data))
      stop(paste0("Site ", i, " does not have sufficient data."))
    
    # Fetch instantaneous flow and gage height data
    site_data_i <- dataRetrieval::read_waterdata_continuous(
      monitoring_location_id = i,
      parameter_code = c("00060", "00065"),
      time = as.POSIXct(c(start_date, end_date))
    )
    
    # Format instantaneous data frame
    flow_data_i <- site_data_i %>%
      subset(parameter_code == "00060") %>%
      dplyr::select(site_no = monitoring_location_id,
                    datetime_local = time,
                    flow_cfs = value)
    
    gage_data_i <- site_data_i %>%
      subset(parameter_code == "00065") %>%
      dplyr::select(
        site_no = monitoring_location_id,
        datetime_local = time,
        gage_height_ft = value
      )
    
    site_data_i <- dplyr::full_join(flow_data_i, gage_data_i)
    
    # Format metadata data frame
    site_metadata_i <- query %>% 
      select(site_no = monitoring_location_id, 
             site_name = monitoring_location_name,
             timezone = time_zone_abbreviation) %>%
      sf::st_set_crs(4326) %>%
      dplyr::mutate(
        lon = sf::st_coordinates(geometry)[, 1],
        lat = sf::st_coordinates(geometry)[, 2]) %>%
      dplyr::filter(dplyr::row_number() == 1)
    
    # Append all results into single data frame
    site_data <- rbind(site_data_i, site_data)
    site_metadata <- rbind(site_metadata_i, site_metadata)
  }
  
  return(list(data = site_data, metadata = site_metadata))
}

#' @title Fetch Weather Data From Open Meteo
#' @description Fetch precipitation data from Open Meteo
#' \link{https://open-meteo.com/en/docs/historical-weather-api#api_form}
#' @export
#' @param site_metadata A data frame containing the columns \code{site_number,
#' lat, lon} where \code{site_number} corresponds to the USGS site number,
#' \code{lat} to the latitudinal coordinate of the given site and \code{lon} 
#' to the longitudinal coordinate of the given site.
#' @param start_date Start date, provide as \code{"YYYY-mm-dd"}.
#' @param end_date End date, provide as \code{"YYYY-mm-dd"}.
#' @return A data frame containing a time series of precipitation data
#' in local date time and inches.
#'
fetch_weather_data <- function(site_metadata,
                               start_date,
                               end_date) {
  # Initiate data frames for appending
  weather_data <- c()
  for (i in 1:nrow(site_metadata)) {
    # GET request
    url <- paste0(
      "https://archive-api.open-meteo.com/v1/archive?latitude=",
      site_metadata$lat[i],
      "&longitude=",
      site_metadata$lon[i],
      "&start_date=",
      start_date,
      "&end_date=",
      end_date,
      "&timezone=",
      site_metadata$timezone[i],
      "&hourly=precipitation&hourly=temperature_2m&format=json"
    )
    
    # Fetch json
    weather_json <- jsonlite::fromJSON(url)
    
    # Convert json to data frame
    # Extract time series data and convert to local timezone
    # Convert mm to inches and C to F
    weather_data_i <- weather_json %>%
      purrr::pluck("hourly") %>%
      dplyr::bind_rows() %>%
      dplyr::mutate(
        site_number = site_metadata$site_no[i],
        datetime_local = as.POSIXct(time,
                                    format = "%Y-%m-%dT%H:%M",
                                    tz = site_metadata$timezone[i]),
        precipitation = precipitation * 0.0394,
        temp_degF = 9 / 5 * temperature_2m + 32
      ) %>%
      dplyr::select(site_number,
                    datetime_local,
                    precipitation_in = precipitation,
                    temp_degF)
    weather_data <- rbind(weather_data_i, weather_data)
  }
  
  return(weather_data)
}
