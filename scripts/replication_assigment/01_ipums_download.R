###############################################################################
# ECON GU4911 -- Household and Real Estate Finance
# Download the IPUMS USA microdata for to be able to replicate Table 2
#   in Ali (2022). Will be done
#   directly from R, using the ipumsr package and the IPUMS API.
#
# This is a DRAFT template. It automates the same extract you would otherwise
#   build by hand on the IPUMS USA website (see data-download-instructions.md).
#   You still need your own free IPUMS account and an API key.
#
# ipumsr documentation: https://tech.popdata.org/ipumsr/
# API workflow guide:    https://tech.popdata.org/ipumsr/articles/ipums-api-micro.html
#
# IMPORTANT: this download is LARGE (eight full-count-adjacent samples,
#   1920-1970). It can take a while to process on IPUMS's side and to download.
#   It is needed to start the replication following the structure of the paper's
#   replication package.
#
# INPUTS   : IPUMS API (needs an API key)
# OUTPUTS  : data/IPUMS data/usa_00005.dat.gz  # raw Census extract
###############################################################################


# ----------------------------------------------------------------------------
# 0. Setup
# ----------------------------------------------------------------------------
library(here)
library(ipumsr)
library(dplyr)
library(assertthat)

# Where to save the downloaded data. Point this at the assignment data folder.
here::i_am("scripts/01_ipums_download.R")
download_dir <- here("data", "IPUMS data")
if (!dir.exists(download_dir)) dir.create(download_dir, recursive = TRUE)


# ----------------------------------------------------------------------------
# 1. Register your IPUMS API key  (ONE TIME)
# ----------------------------------------------------------------------------
# Get a free key at:  https://account.ipums.org/api_keys
# Store it once in your ~/.Renviron so you never hard-code it and no one else
#   can see it if you share your code. You can do this by typing in a separate
#   R session:
#     set_ipums_api_key("YOUR_KEY_HERE", save = TRUE)   # writes to .Renviron


# If you saved it previously, ipumsr will find it automatically and you can
#   skip this step.


# ----------------------------------------------------------------------------
# 2. Confirm the sample codes  (recommended -- do not skip)
# ----------------------------------------------------------------------------
# Sample codes change/expand over time, so verify the exact IDs against the
#   live catalog rather than trusting a hard-coded list.
samples_available <- get_sample_info("usa")
# View(samples_available)   # search the 'description' column for the 8 samples

# The eight samples used by Ali (2022), with their LIKELY IPUMS codes.
#   >>> VERIFY each code against samples_available before submitting. <<<
#   The 1970 "Form 1 / Form 2 Metro" samples in particular have several
#   variants -- match the 'description' text exactly.
target_samples <- c(
  "us1920a",  # 1920 1%
  "us1930a",  # 1930 1%
  "us1940a",  # 1940 1%
  "us1950a",  # 1950 1%
  #"us1960a",  # 1960 1% (no county IDs here,
  #according to https://forum.ipums.org/t/county-identifiers-1940-1960/5781)
  "us1960b",  # 1960 5%
  #"us1970c"  # 1970 Form 1 Metro does not have SCHOOL,
  # so use Form 2 Metro instead (us1970d)
  # https://usa.ipums.org/usa-action/variables/SCHOOL#availability_section
  "us1970d"   # 1970 Form 2 Metro
)

# ----------------------------------------------------------------------------
# 3. Define the extract
# ----------------------------------------------------------------------------
# Variables from the replication package README (analysis + geography + weights).
# NOTE: mixing plain strings with a var_spec() object requires a list(), not c().
# RELATE uses server-side "case selection" to keep only household heads, so the
#   extract itself is restricted to RELATE == 1 (general code) -- no post-download
#   filter needed, and the download is far smaller. case_selection_type defaults
#   to "general"; the default keeps only the matching individuals (the heads).
target_variables <- list(
  # analysis variables:
  "YEAR", "OWNERSHP", "VALUEH",
  var_spec("RELATE", case_selections = "1"),  # 1 = Head/Householder (see below)
  "SEX", "AGE", "MARST",
  "RACE", "HISPAN", "SCHOOL", "EMPSTAT", "OCCSCORE",
  # county/state geography used to build county codes:
  "STATEICP", "COUNTYICP", "STATEFIP", "COUNTYFIP"
  # (SAMPLE, SERIAL, PERWT etc. are attached automatically)
)

usa_extract <- define_extract_micro(
  collection  = "usa",
  description = "GU4911 -- Ali (2022) FHA & racial inequality replication",
  samples     = target_samples,
  variables   = target_variables
)

usa_extract   # print to inspect before submitting


# ----------------------------------------------------------------------------
# 4. Submit, wait, download, read
# ----------------------------------------------------------------------------
# submit -> poll until ready -> download the .dat.gz + .xml codebook.
submitted <- submit_extract(usa_extract)
ready     <- wait_for_extract(submitted)          # blocks until IPUMS finishes

paths <- download_extract(ready, download_dir = download_dir, overwrite = TRUE)
# For microdata, download_extract() returns the path to the DDI (.xml) codebook.
cat("Downloaded to:", download_dir, "\n")

# Read the codebook and confirm the RELATE case selection meant what we assumed.
# Value labels come from the codebook, so they list every RELATE category even
#   though the data now contain only heads -- which is what lets us verify that
#   general code 1 is "Head/Householder".
ddi <- read_ipums_ddi(paths)

relate_labels <- ipums_val_labels(ddi, RELATE)
print(relate_labels)
assert_that(
  "Head/Householder" %in% relate_labels$lbl[relate_labels$val == 1],
  msg = "RELATE code 1 is not 'Head/Householder' -- re-check the codebook."
)

# Read the data (already restricted to household heads by the extract above).
# This can use a lot of memory even after case selection:
# check_data <- read_ipums_micro(ddi)