# 04_nhgis_dataprep.R ------------------------------------------------
# ECON GU4911 -- Household and Real Estate Finance
# Builds the standardized 1940 county controls from the raw NHGIS
#   extract -- the free public substitute for the paper's paid Social Explorer
#   controls. NHGIS column codes can change, so map them against the codebook.
#
# INPUTS   : data/Social Explorer data/nhgis0001_csv.zip # 03_nhgis_download.R (or manual download)
# OUTPUTS  : proc/nhgis_1940_county.csv  # z-scored 1940 controls, keyed by fips

library(here)
library(ipumsr)
library(dplyr)
library(stringr)
library(readr)
library(assertthat)

here::i_am("scripts/04_nhgis_dataprep.R")
if (!dir.exists(here("proc"))) dir.create(here("proc"), recursive = TRUE)

# Read the downloaded raw NHGIS data ---------------------------------------
nhgis_raw <- read_ipums_agg(
  here("data", "Social Explorer data", "nhgis0001_csv.zip")
)
# ^ adapt to your downloaded file path, NHGIS/IPUMS renames files automatically
# when you download via API, so check the zip name in your data/Social Explorer data/ folder.

# Build variables the analysis expects -------------------------------------
# Build a 5-digit county FIPS from the NHGIS state/county codes (STATEA/COUNTYA),
#   then map the cryptic NHGIS codes (e.g. "BXXXXX001") to named controls using
#   the codebook. NHGIS stores these codes in its "x10" convention with a
#   trailing zero (Alabama STATEA "010", Autauga COUNTYA "0010"), so the real
#   2-digit state and 3-digit county FIPS are the leading digits of each.
nhgis_clean <- nhgis_raw |>
  mutate(fips = str_c(str_sub(STATEA, 1, 2), str_sub(COUNTYA, 1, 3))) |>
  transmute(
    fips,
    total_pop         = BV7001,
    black_pop         = BYA003,
    white_pop         = BYA001 + BYA002,
    foreign_born      = BYA002,
    housing_units     = BXR001,
    employed          = BW7001 + BW7002,
    seeking_work      = BXC001 + BXC002,
    emergency_workers = BXB001 + BXB002
  ) |>
  # A few NHGIS rows are pseudo-counties (e.g. Yellowstone National Park) whose
  #   truncated code collides with a real county's FIPS. Fold them into that
  #   county by summing, so fips is unique before standardization.
  group_by(fips) |>
  summarise(across(everything(), ~ sum(.x, na.rm = TRUE)), .groups = "drop")

# Add a z-scored copy of each analysis variable, suffixed "_standardized", so
#   both the raw counts and the standardized versions are kept (fips unchanged).
nhgis_clean <- nhgis_clean |>
  mutate(across(-fips, ~ as.numeric(scale(.x)), .names = "{.col}_standardized"))

# Validate standardization: each *_standardized control has mean ~0 and sd ~1.
tol   <- 1e-8
std   <- nhgis_clean |> select(ends_with("_standardized"))
means <- std |> summarise(across(everything(), ~ mean(.x, na.rm = TRUE))) |> unlist()
sds   <- std |> summarise(across(everything(), ~ sd(.x,   na.rm = TRUE))) |> unlist()
for (v in names(means)) {
  assert_that(isTRUE(all.equal(unname(means[[v]]), 0, tolerance = tol)),
              msg = str_c("Standardization check failed for mean of ", v))
  assert_that(isTRUE(all.equal(unname(sds[[v]]), 1, tolerance = tol)),
              msg = str_c("Standardization check failed for sd of ", v))
}

# Save controls for 05_fha_dataprep.R to merge ------------------------------
write_csv(nhgis_clean, here("proc", "nhgis_1940_county.csv"))
message("Wrote proc/nhgis_1940_county.csv -- 05_fha_dataprep.R will now use it.")