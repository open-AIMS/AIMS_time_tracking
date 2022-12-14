library(targets)
library(tidyverse)
source("run.R")
source("R/functions.R")
# load all objects to global environment
targets::tar_load_everything()
# make table reportable in timesheet format for any given date window
t_s <- compute_timesheet(
  time_tracking_table,
  min_day = as.Date("2022-07-01"), max_day = as.Date("2022-07-02")
) %>%
  data.frame %>%
  tidyr::pivot_wider(names_from = "Day", values_from = "total_hours")
# calculate total number of hours worked per day
t_s %>%
  tibble::column_to_rownames("Task") %>%
  dplyr::select(starts_with("20")) %>%
  colSums(na.rm = TRUE)

# compute time spent during the entire financial year
compute_timesheet(time_tracking_table,
                  min_day = as.Date("2022-07-01"),
                  max_day = as.Date("2023-06-30")) %>%
  dplyr::group_by(Task, code) %>%
  dplyr::summarise(total_hours = sum(total_hours),
                   fte_days = total_hours / 8.1666666) %>%
  dplyr::arrange(-fte_days) %>%
  data.frame

# calculate FTE usage for a project within a defined date window
# code 21 is Project A
calc_fte_usage(time_tracking_table, min_day = as.Date("2022-07-01"),
               max_day = as.Date("2022-12-13"), code_column = "code",
               target_code = 21)

# calculate FTE spent in meetings within a defined date window
calc_fte_usage(time_tracking_table, min_day = as.Date("2022-07-01"),
               max_day = as.Date("2022-12-13"), code_column = "usage_code",
               target_code = "meeting")

# check hours of current week
aims_like_timesheet %>%
  dplyr::group_by(Day) %>%
  dplyr::summarise(hours = sum(total_hours))
aims_like_timesheet %>%
  dplyr::group_by(Day) %>%
  dplyr::summarise(hours = sum(total_hours)) %>%
  dplyr::summarise(mean(hours))
