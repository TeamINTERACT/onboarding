0. Ensure tidyverse, dplyr is installed and loaded:
```
install.packages("tidyverse")
library("tidyverse")
install.packages("dplyr")
library("dplyr")
```

## CCHS Data:

1. Read in the data cchs.csv
```
cchs <- read_csv("csv_file_location/cchs.csv")
```

2. Quickly view the first 10 rows of data
```
head(cchs, 10)
```

3. Display the type of variable for all variables in the dataset
```
sapply(cchs, class)
```

4. Create a scatterplot on height and weight
```
ggplot(cchs, aes(x = hwtghtm, y = hwtgwtk)) + geom_point()
```

5. Clean the height and weight data so missing data coded as numbers become NA in R
```
# Worse
cchs_clean <- cchs %>% mutate(hwtghtm = factor(hwtghtm))
cchs_clean <- cchs_clean %>% mutate(hwtgwtk = factor(hwtgwtk))
cchs_clean <- cchs_clean %>% mutate(hwtghtm = fct_recode(hwtghtm, NULL = "9.996", NULL = "9.999"))
```

```
# Better
cchs_clean <- cchs %>% mutate(hwtghtm = case_when(
	hwtghtm > 8.0 ~ NA_real_,
	TRUE ~ hwtghtm
))
cchs_clean <- cchs_clean %>% mutate(hwtgwtk = case_when(
	hwtgwtk > 900.0 ~ NA_real_,
	TRUE ~ hwtgwtk
))
```

6. Create a new scatterplot on height and weight with the clean data
```
ggplot(cchs_clean, aes(x = hwtghtm, y = hwtgwtk)) + geom_point()
```

7. Recode BMI to represent weight categories from underweight to obese
```
cchs_clean <- cchs_clean %>%
	mutate(bmi_category = case_when(
		hwtgbmi < 18.5 ~ "underweight",
		hwtgbmi >=30 & hwtgbmi <999 ~ "obese",
		hwtgbmi >=25 & hwtgbmi <30 ~ "overweight",
		hwtgbmi >=18.5 & hwtgbmi <25 ~ "normal weight",
		TRUE ~ "other"
	))
```


8. Recode Province to include the province names instead of numbers
```
cchs_clean <- cchs_clean %>%
	mutate(geogprv_name = case_when(
		geogprv == 10 ~ "NFLD & LAB",
		geogprv == 11 ~ "PEI",
		geogprv == 12 ~ "NOVA SCOTIA",
		geogprv == 13 ~ "NEW BRUNSWICK",
		geogprv == 24 ~ "QUEBEC",
		geogprv == 35 ~ "ONTARIO",
		geogprv == 46 ~ "MANITOBA",
		geogprv == 47 ~ "SASKATCHEWAN",
		geogprv == 48 ~ "ALBERTA",
		geogprv == 59 ~ "BRITISH COLUMBIA",
		geogprv == 60 ~ "YUKON/NWT/NUNA",
		geogprv == 96 ~ "NOT APPLICABLE",
		geogprv == 97 ~ "DON'T KNOW",
		geogprv == 98 ~ "REFUSAL",
		TRUE ~ "NOT STATED"
	))
```

9. Compute the mean and standard deviation of height and weight
```
summarize(
	cchs_clean, 
	avg_ht = mean(hwtghtm, na.rm = T), 
	sd_ht = sd(hwtghtm, na.rm = T),
	avg_wt = mean(hwtgwtk, na.rm = T), 
	sd_wt = sd(hwtgwtk, na.rm = T)
	)
```

10. Compute the mean and standard deviation of height and weight
```
summarize(
	group_by(cchs_clean, bmi), 
	avg_ht = mean(hwtghtm, na.rm = T), 
	sd_ht = sd(hwtghtm, na.rm = T),
	avg_wt = mean(hwtgwtk, na.rm = T), 
	sd_wt = sd(hwtgwtk, na.rm = T)
	)
summarize(
	group_by(cchs_clean, geogprv_name), 
	avg_ht = mean(hwtghtm, na.rm = T), 
	sd_ht = sd(hwtghtm, na.rm = T),
	avg_wt = mean(hwtgwtk, na.rm = T), 
	sd_wt = sd(hwtgwtk, na.rm = T)
	)
```



## Accel Data

1. Read in the 2 data files `accel_participantX.csv`
```
accel_1 = read_csv("onboard/accel_participant1.csv")
accel_2 = read_csv("onboard/accel_participant2.csv")
```

2. Create a new variable that indicates participant 1 and participant 2
```
accel_1$participant = 1
accel_2$participant = 2
```

3. Append (stack) the 2 files together
```
accel_data = bind_rows(accel_1, accel_2)
```

4. Quickly view the first 10 rows of data
```
head(accel_data, 10)
```

5. Display the type of variable for all variables in the dataset
```
sapply(accel_data, class)
```

6. Create a scatterplot on x_axis and y_axis
```
ggplot(accel_data, aes(x = x_axis, y = y_axis)) + geom_point()
```

8. Convert the time data to time format
```
accel_data <- accel_data %>% mutate(time = ymd_hms(substr(time, 1, nchar(time)-4)))
```

9. Compute the sum of each axis by second and by participant
```
summarize(
    group_by(accel_data, time, participant),
    avg_x = mean(x_axis),
    avg_y = mean(y_axis),
    avg_z = mean(z_axis)
)
```

10. Compute the gravity subtracted vector magnitude sqrt(x^2, y^2, z^2)-1 on the new data for each participant
```
accel_avg$gravity <- sqrt(accel_avg$avg_x^2 + accel_avg$avg_y^2 + accel_avg$avg_z^2)-1
```

## Database

2. Open the connection to the interact_demo database, then use `tbl()` to get a reference
to each of the tables in it.

```
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "interact_demo",
    host = "yakitori.usask.ca", port = 5432,
    user = rstudioapi::askForPassword("Database user"), 
    password = rstudioapi::askForPassword("Database password"))
demo_accel <- tbl(con, "accel_data")
demo_cchs <- tbl(con, "cchs")
```

3. View the first ten rows of each table.
```
demo_accel %>% head(10)
demo_cchs %>% head(10)
```

4. Display rows from the cchs table where the data originates in Saskatchewan.
```
demo_cchs %>% filter(geogprv == 47)
```

5. Display only the caseid column from the cchs table, where the data originates from 
Ontario
```
demo_cchs %>% filter(geogprv == 35) %>% select(caseid)
```

6. Display the average BMI by province from the cchs table
```
demo_cchs %>% filter(hwtgbmi < 50) %>%
	group_by(geogprv) %>%
	summarise(avg_bmi = mean(hwtgbmi))
```
