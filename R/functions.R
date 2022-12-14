match_item_category <- function(x, aims_categories, project_codes, date_flag) {
  if (length(x) > 1) {
    stop("On date ", date_flag, " of time_tracking raw file: ",
         "there should be only one activity per time slot")
  }
  item <- gsub("- ", "", x, fixed = TRUE) %>%
    strsplit(" / ", fixed = TRUE) %>%
    `[[`(1)
  out_aims <- aims_categories[aims_categories$code == item[3], ]
  rownames(out_aims) <- NULL
  out_code <- project_codes[project_codes$usage_code == item[2], ]
  rownames(out_code) <- NULL
  if (nrow(out_aims) == 0) {
    stop("On date ", date_flag, " , with flag ", x, ". Non-matching item")
  } else if (nrow(out_code) == 0) {
    out_code <- data.frame(project_name = "aims_general",
                           usage_code = NA, stringsAsFactors = FALSE)
  }
  cbind(out_aims, out_code)
}

fetch_window <- function(x, data, index) {
  list(
    "begin" = x[index] + 1,
    "end" = ifelse(index == length(x), length(data), x[index + 1] - 1)
  )
}

clean_hour <- function(hour) {
  tolower(gsub("* ", "", hour, fixed = TRUE))
}

create_time_stamp <- function(day, hour) {
  as.POSIXct(paste(day, hour), format = "%Y-%m-%d %H:%M")
}

calc_time_worked <- function(day, hour_beg, hour_end) {
  hours <- do.call(clean_hour, list(c(hour_beg, hour_end)))
  if (!is.na(hours[2])) {
    if (hours[1] == "morning") {
      4 + 5 / 60 # 4 hours, 5 minutes
    } else if (hours[1] == "afternoon") {
      begin <- create_time_stamp(day, "12:30")
      end <- create_time_stamp(day, hours[2])
      as.numeric(difftime(end, begin), units = "hours")
    } else {
      begin <- create_time_stamp(day, hours[1])
      end <- create_time_stamp(day, ifelse(hours[2] == "afternoon", "12:00",
                                           hours[2]))
      as.numeric(difftime(end, begin), units = "hours")
    }
  } else {
    if (hours[1] == "morning" | hours[1] == "afternoon") {
      4 + 5 / 60
    } else {
      hour <- as.numeric(substr(hours[1], 1, 2))
      minu <- as.numeric(substr(hours[1], 4, 5))
      if (hour < 12) {
        end_hour <- "12:00"
      } else if (hour >= 12 & hour < 16) {
        end_hour <- "16:40"
      } else if (hour == 16 & minu <= 40) {
        end_hour <- "16:40"
      } else if (hour == 16 & minu > 40 | hour > 16) {
        end_hour <- hours[1]
      }
      begin <- create_time_stamp(day, hours[1])
      end <- create_time_stamp(day, end_hour)
      as.numeric(difftime(end, begin), units = "hours")
    }
  }
}

gen_time_table <- function(data, aims_categories, project_codes) {
  day_pos <- grep("# ", data, fixed = TRUE)
  days <- gsub("# ", "", data[day_pos], fixed = TRUE) %>%
    as.Date(format = "%Y-%m-%d")
  time_table <- vector(mode = "list", length = length(day_pos))
  for (i in seq_along(day_pos)) {
    win <- fetch_window(day_pos, data, i)
    meat <- data[win$begin:win$end]
    stamps <- grep("*", meat, fixed = TRUE)
    if (length(stamps) > 0) {
      out <- vector(mode = "list", length = length(stamps))
      for (j in seq_along(stamps)) {
        win <- fetch_window(stamps, meat, j)
        meat2 <- meat[win$begin:win$end]
        out[[j]] <- match_item_category(meat2, aims_categories,
                                        project_codes, days[i]) %>%
          dplyr::mutate(
            Day = days[i],
            Time_started = meat[stamps[j]],
            Time_spent_hours = calc_time_worked(
              days[i], meat[stamps[j]], meat[stamps[j + 1]]
            )
          )
      }
      out <- do.call("rbind.data.frame", out)
    } else {
      out <- match_item_category(meat, aims_categories, project_codes,
                                 days[i]) %>%
        dplyr::mutate(Day = days[i], Time_started = "* Morning",
                      Time_spent_hours = 8 + 10 / 60)
    }
    if (any(is.na(out$Category))) {
      browser()
    }
    time_table[[i]] <- out
  }
  out <- do.call("rbind.data.frame", time_table)
  out[out$Category != "Personal", ]
}

summarise_table <- function(data) {
  data %>%
    dplyr::mutate(week = format(Day, "%U"),
                  month = format(Day, "%m"),
                  year = format(Day, "%Y")) %>%
    dplyr::group_by(week, month, year, code, Task) %>%
    dplyr::summarise(total_hours = round(sum(Time_spent_hours), 2)) %>%
    data.frame
}

compute_timesheet <- function(data, min_day, max_day) {
  if (missing(min_day) | missing(max_day)) {
    min_day <- as.Date(cut(Sys.Date(), "week"))
    max_day <- min_day + 4
  }
  data %>%
    dplyr::select(Task, code, Day, Time_spent_hours) %>%
    dplyr::filter(Day >= min_day & Day <= max_day) %>%
    dplyr::group_by(Day, Task, code) %>%
    dplyr::summarise(total_hours = sum(Time_spent_hours)) %>%
    dplyr::ungroup()
}

calc_fte_usage <- function(time_tracking_table, min_day, max_day,
                           code_column, target_code) {
  data_to_date <- time_tracking_table %>%
    dplyr::filter(Day >= as.Date(min_day))
  data_period <- data_to_date %>%
    dplyr::filter(Day <= as.Date(max_day))
  data_task <- data_period %>%
    dplyr::rename(chosen_col = tidyselect::all_of(code_column)) %>%
    dplyr::filter(!is.na(chosen_col),
                  chosen_col == target_code)
  total_hours <- sum(data_to_date$Time_spent_hours)
  period_hours <- sum(data_period$Time_spent_hours)
  task_hours <- sum(data_task$Time_spent_hours)
  list(total_hours = total_hours, period_hours = period_hours,
       task_hours = task_hours,
       fte_to_completion = round(task_hours / period_hours, 3),
       fte_to_date = round(task_hours / total_hours, 3))
}
