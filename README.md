# An R-based time-tracking tool

This repository contains code and data needed which generate a simple table for work time tracking purposes

Copyright (c) 2022, Australian Institute of Marine Science and Dr Diego Barneche

## Instructions

All analyses were done in `R`. This routine uses the [targets](https://github.com/ropensci/targets) R package to compile the output time table. First install `targets`:

```r
install.packages("targets")
```

Next you need to open an R session with working directory set to the root of the project.

This routine uses some packages detailed under `_targets.R`, so make sure to install them before running anything.

Then, to generate the time tracking table, simply run:

```r
source("run.R")
targets::tar_load_everything()
time_tracking_table # for full dataset
simplified_time_tracking_table # for simplified dataset
aims_like_timesheet # for AIMS-style timesheet reporting for the current week
```

Note that by default the target `aims_like_timesheet` reports on the current (i.e. relative to when `source("run.R")` is called) working week. A series of extra useful examples, including on how to calculate time spent for specific windows of time, are provided under `analyse.R`.

The actual time records are kept and updated in the `data/time_tracking.txt` file. The structure is quite simple: `#` sets the day (in YYYY-MM-DD format), `*` sets the time stamp (either categorical: `Morning` or `Afternoon`, or numerical as in `HH::MM`), and `-` sets the actual task being tackled. The task description follows the pattern `task_name / usage_code / task_number`. `usage_code` is a general description of the activity (it could be writing, coding, meeting, planning, not simply nothing), and it is matched to a usage code placed under `data/usage_codes.csv`--the user can fully customise that table; it can be an empty value in case `task_name` isn't associated with a particular usage; in those instances, a general `aims_general` project code will be assigned when `target` runs. `task_number` is matched to a work category defined by AIMS which is placed under `data/aims_categories.csv`; **NB:** this cannot be empty. If needed, new `task_number`s can be added to `data/aims_categories.csv`. Also, at present, a time stamp only accepts one task.

### How to download this project for people not familiar with GitHub:  
* on the project main page on GitHub, click on the green button `clone or download` and then click on `Download ZIP`  

## Bug reporting
* Please [report any issues or bugs](https://github.com/open-AIMS/AIMS_time_tracking/issues).
