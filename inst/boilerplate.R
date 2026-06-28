library(deloRean)
library(opentimeseries)
library(xlsx)

## Example Step 2, Generate History

library(tsdbapi)
keys <- read_dataset_keys("ch.kof.trsm")
length(keys)

# select only public keys:
ws <- keys[startsWith(keys, "ch.kof.trsm.fcst.ws")]
length(ws)
# select only the keys that are in the publicly available xlsx from the kof
kws <- read.xlsx("kof_trsm_ws.xlsx", sheetIndex = 1)
nkws <- names(kws)[-1]
length(nkws) # 12
# Check which keys from the tsdbapi list are also present in the public xlsx names
match_ws <- ws[ws %in% nkws]
length(match_ws) # 12 -> matches

all_vintages <- read_ts_history(match_ws)
str(all_vintages) # to see the latest vintage, if the series is up to date

# read_ts_history returns names as key_YYYYMMDD; convert to key.YYYY-MM
# so that create_vintage_dt can strip the .YYYY-MM suffix to recover the key
vintage_date_str <- sub(".+_([0-9]{8})$", "\\1", names(all_vintages))
vintage_dates <- as.Date(vintage_date_str, format = "%Y%m%d")
names(all_vintages) <- sub("_([0-9]{4})([0-9]{2})[0-9]{2}$", ".\\1-\\2", names(all_vintages))
# remove the dataset prefix so keys match the relative key structure in the archive
names(all_vintages) <- sub("^ch\\.kof\\.trsm\\.fcst\\.ws\\.", "", names(all_vintages))
class(all_vintages) <- c(class(all_vintages), "tslist")


## Step 3: Create vintages data.table
vintages_dt <- create_vintage_dt(vintage_dates, all_vintages)
head(vintages_dt, n = 100)

archive_import_history(vintages_dt, repository_path = ".")


## Step 5: Write & Validate Metadata

# check if info is available via api
# metadata is usually available in german, i.e. locale = "de"
indpau_meta <- read_dataset_ts_metadata("ch.kof.trsm", locale = "en")

render_metadata()
meta <- read_metadata(".")
validate_metadata(meta) # TRUE

## Step 6: Write handle_update & process_data

## Step 7: Seal Archive
key <- "..."
devtools::load_all()
library(digest)
checksum_input <- generate_checksum_input(key = key)
archive_seal(checksum_input)

## Step 8: Check CRON schedule
# check if the cron schedule in .github/workflows/update_data.yaml
# is adequate for the dataset

## Step 9: Final Checks & Automation
devtools::load_all()
handle_update(key = key)

library(devtools)
check()
document()

## Step 10: Build Readme
# 1. write an example tsplot into the last code snippet of the Readme.Rmd
# 2. push the package & transfer to opentsi if needed (s.t. the example works)
build_readme() # 3.
