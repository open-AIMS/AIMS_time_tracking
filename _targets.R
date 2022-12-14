library(targets)
source("R/functions.R")
options(tidyverse.quiet = TRUE)
rstan::rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
tar_option_set(packages = c("dplyr", "tidyselect"))
list(
  tar_target(
    tt_file_path, "data/time_tracking.txt", format = "file"
  ),
  tar_target(
    cat_file_path, "data/aims_categories.csv", format = "file"
  ),
  tar_target(
    ucodes_file_path, "data/usage_codes.csv", format = "file"
  ),
  tar_target(data, readLines(tt_file_path)),
  tar_target(aims_categories, {
    read.csv(cat_file_path, header = TRUE, stringsAsFactors = FALSE,
             strip.white = TRUE, na.strings = c("", NA)) %>%
      dplyr::mutate(code = as.character(code))
  }),
  tar_target(usage_codes, {
    read.csv(ucodes_file_path, header = TRUE, stringsAsFactors = FALSE)
  }),
  tar_target(time_tracking_table, {
    gen_time_table(data, aims_categories, usage_codes)
  }),
  tar_target(simplified_time_tracking_table, {
    summarise_table(time_tracking_table)
  }),
  tar_target(aims_like_timesheet, {
    compute_timesheet(time_tracking_table)
  })
)
