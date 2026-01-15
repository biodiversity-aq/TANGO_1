library(geosphere)
library(here)
library(hms)
library(janitor)
library(lubridate)
library(readxl)
library(tidyverse)

# load data
events <- read_excel(here("data", "02_interim", "TANGO_1_DATA_cleaned.xlsx"), sheet = "Events") %>%
  clean_names(case = "lower_camel") %>%
  select(!where(~ all(is.na(.))))  # remove empty columns

gear_protocol <- read_tsv(here("data", "01_raw", "gear_protocol.tsv")) 

samples <-  read_excel(here("data", "02_interim", "TANGO_1_DATA_cleaned.xlsx"), sheet = "Samples") %>%
  clean_names(case = "lower_camel") %>%
  select(!where(~ all(is.na(.))))  # remove empty columns

# clean events
events_clean <- events %>%
  rename(
    parentEventID = parentEventId,
    eventID = eventId,
    maximumElevationInMeters = maxAltitudeM,
    minimumDepthInMeters = minimumDepthM,
    maximumDepthInMeters = maximumDepthM
  ) %>%
  mutate(
    parentEventID = "https://www.wikidata.org/entity/Q119843670",
    samplingProtocol = if_else(
      is.na(gearType),
      NA_character_,
      paste0(
        gearType,
        " | https://doi.org/10.5281/zenodo.8013721 | ",
        gear_protocol$samplingProtocol[
          match(gearType, gear_protocol$gear_type)
        ]
      )
    ),
    maximumElevationInMeters = round(maximumElevationInMeters, 0),
    # move habitat == Aerial to eventRemarks
    eventRemarks = case_when(
      habitat == "Aerial" & is.na(eventRemarks) ~
        "Event documented using UAV (drone) imagery",
      
      habitat == "Aerial" & !is.na(eventRemarks) ~
        paste(eventRemarks, "UAV (drone) imagery used", sep = " | "),
      
      TRUE ~ eventRemarks),
    # location
    locality = case_when(stationName == "Transect" ~ "", TRUE ~ stationName),
    higherGeographyID = case_when(
      locality == "Dodman Island" ~ "https://data.aad.gov.au/aadc/gaz/scar/display_name.cfm?gaz_id=108535",
      locality == "Blaiklock Island" ~ "https://data.aad.gov.au/aadc/gaz/scar/display_name.cfm?gaz_id=107831",
      locality == "Grandidier Channel" ~ "https://data.aad.gov.au/aadc/gaz/scar/display_name.cfm?gaz_id=109091",
      TRUE ~ ""
    ),
    # Clean up coordinates
    across(
      c(latitudeStart, longitudeStart, latitudeEnd, longitudeEnd),
      ~ na_if(.x, 0)
    ),
    latitudeStart = round(latitudeStart, 4),
    longitudeStart = round(longitudeStart, 4),
    latitudeEnd = round(latitudeEnd, 4),
    longitudeEnd = round(longitudeEnd, 4),
    # footprintWKT for LINESTRING
    footprintWKT = case_when(
      !is.na(latitudeStart) & !is.na(longitudeStart) & !is.na(latitudeEnd) & !is.na(longitudeEnd) ~
        paste0("LINESTRING (", sprintf("%.4f", longitudeStart), " ", 
               sprintf("%.4f", latitudeStart), ", ", 
               sprintf("%.4f", longitudeEnd), " ", 
               sprintf("%.4f", latitudeEnd), ")"),
      TRUE ~ NA_character_
    ),
    # decimalLatitude and decimalLongitude
    decimalLatitude = case_when(
      # midpoint for line
      !is.na(latitudeStart) & !is.na(latitudeEnd) ~ round((latitudeStart + latitudeEnd) / 2, 4),
      !is.na(latitudeStart) & is.na (latitudeEnd) ~ latitudeStart,
      TRUE ~ NA_real_
    ),
    decimalLongitude = case_when(
      # midpoint for line
      !is.na(longitudeStart) & !is.na(longitudeEnd) ~ round((longitudeStart + longitudeEnd) / 2, 4),
      !is.na(longitudeStart) & is.na (longitudeEnd) ~ longitudeStart,
      TRUE ~ NA_real_
    ),
    # great-circle distance (meters)
    distance_m = distHaversine(
      cbind(longitudeStart, latitudeStart),
      cbind(longitudeEnd, latitudeEnd)
    ),
    coordinateUncertaintyInMeters = round(distance_m / 2, 0),
    
    # default cuim for missing values based on gear type
    # 1) keep a flag of which rows need a default
    cuim_defaulted = is.na(coordinateUncertaintyInMeters),
    # 2) fill ONLY missing coordinateUncertaintyInMeters
    coordinateUncertaintyInMeters = case_when(
      !is.na(coordinateUncertaintyInMeters) ~ coordinateUncertaintyInMeters,
      gearType == "Mavic 2 PRO" ~ 50,
      gearType %in% c("STAR_ODDI DST CTD", "NISKIN 3L") ~ 100,
      gearType == "BlueROV" ~ 500,
      gearType == "SCUBA" ~ 25,
      gearType == "Bombard C4" ~ 100,
      TRUE ~ 1000
    ),
    # 3) append a remark about cuim ONLY when we defaulted it
    eventRemarks = case_when(
      cuim_defaulted & is.na(eventRemarks) ~
        paste0("coordinateUncertaintyInMeters defaulted from gearType=", gearType),
      cuim_defaulted & !is.na(eventRemarks) ~
        paste(eventRemarks, paste0("coordinateUncertaintyInMeters defaulted from gearType=", gearType), sep = " | "),
      TRUE ~ eventRemarks
    ),
    # Convert to UTC by adding 3 hours, time zone was UTC-3
    t_start_utc = as_hms(timeStartUtc3 + (3 * 3600)),
    t_end_utc   = as_hms(timeEndUtc3 + (3 * 3600)),
    
    # eventDate & eventTime Logic
    # Scenario: Multi-day range
    is_multi_day = !is.na(eventDateEnd) & eventDateStart != eventDateEnd,
    eventDate = case_when(
      is_multi_day ~ paste0(eventDateStart, "T", t_start_utc, "Z/", eventDateEnd, "T", t_end_utc, "Z"),
      TRUE         ~ as.character(eventDateStart)
    ),
    
    eventTime = case_when(
      # No start time at all -> NA
      is.na(t_start_utc) ~ NA_character_,
      # Multi-day (times are already in eventDate) -> NA
      is_multi_day ~ NA_character_,
      # Same day, has start and end time
      !is.na(t_end_utc)  ~ paste0(t_start_utc, "Z/", t_end_utc, "Z"),
      # Same day, start time only
      TRUE ~ paste0(t_start_utc, "Z")
    )
  ) %>%
  rowwise() %>%
  mutate(
    recordedBy = paste(
      na.omit(c_across(starts_with("collector") & !ends_with("Orcid"))),
      collapse = " | "
    ),
    recordedBy = if_else(recordedBy == "", NA_character_, recordedBy),
    recordedByID = paste(
      na.omit(c_across(ends_with("Orcid"))),
      collapse = " | "
    ),
    recordedByID = if_else(recordedByID == "", NA_character_, recordedByID)
  ) %>%
  ungroup() 
  
  
tango_1_event <- events_clean %>%  
  select(
    eventID,
    parentEventID,
    samplingProtocol,
    eventDate,
    eventTime,
    eventRemarks,
    locality,
    higherGeographyID,
    decimalLatitude,
    decimalLongitude,
    coordinateUncertaintyInMeters,
    footprintWKT,
    minimumDepthInMeters,
    maximumDepthInMeters,
    maximumElevationInMeters,
    recordedBy,
    recordedByID
  )


# clean samples
samples_clean <- samples %>%
  rename(
    eventID = eventId,
    sampleID = sampleId,
    parentSampleID = parentSampleId,
    scientificNameID = scientificNameId,
    preparations = preservedIn
  ) %>%
  rowwise() %>%
  mutate(
    recordedBy = paste(
      na.omit(c_across(starts_with("recordedBy") & !starts_with("recordedByID"))),
      collapse = " | "
    ),
    recordedBy = if_else(recordedBy == "", NA_character_, recordedBy),
    recordedByID = paste(
      na.omit(c_across(starts_with("recordedByID"))),
      collapse = " | "
    ),
    recordedByID = if_else(recordedByID == "", NA_character_, recordedByID),
    identifiedBy = paste(
      na.omit(c_across(starts_with("identifiedBy") & !starts_with("identifiedByID"))),
      collapse = " | "
    ),
    identifiedBy = if_else(identifiedBy == "", NA_character_, identifiedBy),
    identifiedByID = paste(
      na.omit(c_across(starts_with("identifiedByID"))),
      collapse = " | "
    ),
    identifiedByID = if_else(identifiedByID == "", NA_character_, identifiedByID)
  ) %>%
  ungroup()

# check for non-unique sampleIDs
non_unique_samples <- samples_clean %>% add_count(sampleID) %>% filter(n > 1) 
  

# save cleaned events
write_tsv(events_clean, here("data", "03_output", "tango_1_events.tsv"), na = "")
write_tsv(samples_clean, here("data", "03_output", "tango_1_samples.tsv"), na = "")







