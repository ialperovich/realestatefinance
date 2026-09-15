# 03_nhgis_download.R ------------------------------------------------
# ECON GU4911 -- Household and Real Estate Finance
#
# This is a template. It automates the extract you would otherwise build by hand
#   in the NHGIS Data Finder (see DATA_DOWNLOAD_INSTRUCTIONS.md). You need a free
#   IPUMS account and an API key (the same key works for IPUMS USA microdata and
#   NHGIS). NHGIS dataset/table codes change over time, so verify them against
#   the live catalog before submitting.
#
# INPUTS   : IPUMS API (needs an API key)
# OUTPUTS  : data/Social Explorer data/  # raw NHGIS extract (zip/csv)

library(here)
library(ipumsr)
library(dplyr)

here::i_am("scripts/03_nhgis_download.R")

download_dir <- here("data", "Social Explorer data")
if (!dir.exists(download_dir)) dir.create(download_dir, recursive = TRUE)

# Find the 1940 county dataset ---------------------------------------------
# NHGIS dataset/table codes are cryptic and can change, so look them up from the
#   live catalog instead of hard-coding blindly.
get_metadata_catalog("nhgis", "datasets")
datasets <- get_metadata_nhgis(type = "datasets")

datasets |>
  filter(group == "1940 Census") |>
  select(name, description) |>
  print(n = 50)

# >>> SET THIS to the dataset name you found above: <<<
nhgis_dataset <- "1940_cPHAE"   # verify against the catalog!

# Find the data tables within that dataset ---------------------------------
meta <- get_metadata_nhgis(dataset = nhgis_dataset)
meta$geog_levels          # confirm "county" is available
meta$data_tables |>       # browse tables; pick those covering the controls below
  select(name, description, universe) |>
  print(n = 200)
#   - Total population (NT1)
#   - Population by race (White; Black/Negro) and foreign-born (NT6)
#   - Total housing / dwelling units (NT43)
#   - Persons employed (NT25)
#   - Public emergency workers (NT28B)
#   - Persons seeking work (NT29)

# >>> SET THIS to the table codes you selected: <<<
nhgis_tables <- c("NT1", "NT6", "NT43", "NT25", "NT28B", "NT29")   # check codes!

# Define, submit, wait, download -------------------------------------------
nhgis_ext <- define_extract_agg(
  description = "1940 county controls (Social Explorer substitute)",
  collection  = "nhgis",
  datasets    = ds_spec(nhgis_dataset,
                        data_tables = nhgis_tables,
                        geog_levels = "county"),
  data_format = "csv_no_header"
)

nhgis_ext   # inspect before submitting

submitted <- submit_extract(nhgis_ext)
ready     <- wait_for_extract(submitted)
download_extract(ready, download_dir = download_dir, overwrite = TRUE)
message("Downloaded NHGIS extract to: ", download_dir)
