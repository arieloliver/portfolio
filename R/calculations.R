#' @importFrom magrittr %>%
#' @export
magrittr::`%>%`


#' @title Calculate Linear Rating Curve
#' @description Calculate linear rating curve for USGS stream gage site between
#' a given start and end date
#' @export
#' @param site_number USGS stream gage site number.
#' @return Data frame with slope and intercept for each site number provided.
#' Values are in imperial units.
#'
calculate_linear_rating_curve <- function(site_number) {
  
  linear_model <- c()
  for (i in site_number) {
    # Get field measurements
    field_meas <- dataRetrieval::read_waterdata_field_measurements(monitoring_location_id  = i)
    
    # Get channel geometry measurements
    channel_meas <- dataRetrieval::read_waterdata_channel(monitoring_location_id = i) %>%
      dplyr::mutate(time = as.Date(time)) %>%
      dplyr::select(monitoring_location_id,
                    time,
                    channel_flow,
                    channel_width,
                    channel_velocity) %>%
      sf::st_drop_geometry()
    
    # Select columns for rating curve calculation
    # Remove poor readings and negative values
    measurements <- field_meas %>%
      # Remove Poor and negative readings
      dplyr::filter_out(measurement_rated == "Poor") %>%
      dplyr::filter(parameter_code == "00065", 
                    dplyr::if_all(dplyr::where(is.numeric), ~ .x > 0)) %>%
      dplyr::select(
        monitoring_location_id, 
        time, 
        parameter_code,
        value) %>%
      # Drop coordinates
      sf::st_drop_geometry() %>%
      # Average multiple measurements per site visit
      dplyr::distinct() %>%
      dplyr::group_by(
        monitoring_location_id, 
        time, 
        parameter_code) %>%
      dplyr::summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop_last") %>%
      dplyr::ungroup() %>%
      # Reformat table
      tidyr::pivot_wider(names_from = parameter_code, values_from = mean_value) %>%
      dplyr::rename(gage_height_ft = `00065`) %>%
      # Merge with channel geometry
      dplyr::full_join(., channel_meas) %>%
      # Drop rows with missing data
      tidyr::drop_na() %>%
      # Calculate channel depth from field measurements
      dplyr::mutate(channel_depth = channel_flow / (channel_width * channel_velocity))
    
    # Linear interpolation (y ~ x ::: depth ~ stage)
    depth_rating <- measurements %>%
      dplyr::group_by(monitoring_location_id) %>%
      dplyr::do(depthRating = broom::tidy(lm(channel_depth ~ gage_height_ft, data = .))) %>%
      tidyr::unnest(depthRating) %>%
      dplyr::ungroup()
    
    slope <- depth_rating %>%
      dplyr::filter(term == "gage_height_ft") %>%
      dplyr::select(site_no = monitoring_location_id, slope = estimate)
    
    intercept <- depth_rating %>%
      dplyr::filter(term == "(Intercept)") %>%
      dplyr::select(site_no = monitoring_location_id, int = estimate)
    
    linear_model_i <- dplyr::full_join(slope, intercept, by = "site_no")
    
    # Append all results into single data frame
    linear_model <- rbind(linear_model_i, linear_model)
  }
  
  return(linear_model)
} 
