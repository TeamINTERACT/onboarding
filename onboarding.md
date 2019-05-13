---
title: "INTERACT Onboarding"
author: "Daniel Fuller"
date: '2018-06-18'
output:
  html_document:
    keep_md: yes
---



## INTERACT Onboarding

> [Remember that there is no geek gene](http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1006023)

The purpose of this document is to orient and provide guidance for new trainees and collaborators involved with the INTERACT study. Our aim is to make your integration onto the team straight forward, action oriented, and to help you learn new skills. This document will likely take you between 2 and 3 days to work through. 

This onboarding document is divided into 4 sections: 
1. Glossary
2. R and RStudio
3. Database Connections in RStudio
4. Github

The goal is to point you to existing tutorials or training that will facilitate your work. It is important to remember that you will need to follow the tutorials in detail to get your head around what you are trying to do. Along with the tutorials we will ask that you do activities specific to INTERACT. We will try our best to acknowledge the great people who have contributed to the tutorials you are completing. 

#### Thanks!

- [Jenny Bryan](https://twitter.com/JennyBryan)
- [Amelia McNamara](https://twitter.com/AmeliaMN)
- [Chester Ismay and Patrick C. Kennedy](https://ismayc.github.io/rbasics-book/index.html)

We hope that once you are done, you can confidently use the INTERACT workflow, do awesome analysis, and publish cool papers. 

## R + RStudio

The main tutorial, Intro To R, linked below, focuses on data wrangling and not on data analysis. If possible, please complete this tutorial using the RStudio software downloaded to your local computer, and not by using RStudio in your internet browser. Materials for the tutorial, including the instructional slides, can be downloaded as a ZIP file.

### Tutorial

Coding style is important. Follow the [Hadley](http://adv-r.had.co.nz/Style.html) or [Goolge](https://google.github.io/styleguide/Rguide.xml) style guide. We also use `snake_case` in INTERACT projects. All variables and data should be all lower case with an underscore between each word. All new variables you create or data you export should follow the same convention. 

Complete this tutorial. https://github.com/AmeliaMN/IntroToR/blob/master/README.md

* Not that you should not use on the online RStudio environment but run everything locally on your computer. That means you will need to download the repo as discussed at the beginning of the tutorial. It also means that you will need to be familiary with installing R packages. Here is a quick demo:

    - R can do many statistical and data analyses. They are organized in so-called packages or libraries. With the standard installation, most common packages are installed. There are lots of packages. It’s probable that if you have thought about the analysis, there is a package that is able to do it already. There are two basic steps to using a package:

**Installing the package**
`install.packages("ggplot2")`
**Loading the package**
`library(ggplot2)`

##### Common Errors in R ([from Chester Ismay and Patrick C. Kennedy](https://ismayc.github.io/rbasics-book/index.html))

**1. Error: `could not find function`**

This error usually occurs when a package has not been loaded into R via library, so R does not know where to find the specified function. It’s a good habit to use the library functions on all of the packages you will be using in the top R chunk in your R Markdown file, which is usually given the chunk name setup.  

**2. Error: `object not found`**

This error usually occurs when your R Markdown document refers to an object that has not been defined in an R chunk at or before that chunk. You’ll frequently see this when you’ve forgotten to copy code from your R Console sandbox back into a chunk in R Markdown.  

**3. Misspellings**

One of the most frustrating errors you can encounter in R is when you misspell the name of an object or function. R is not forgiving on this, and it won’t try to automatically figure out what you are referring to. You’ll usually be able to quite easily figure out that you made a typo because you’ll receive an object not found error.

Remember that R is also case-sensitive, so if you called an object Name and then try to call it name later on without name being defined, you’ll receive an error.

**4. Unmatched parenthesis**

Another common error is forgetting or neglecting to finish a call to a function with a closing ). An example of this follows:

`mean(x = c(1, 5, 10, 52)`  

```
Error in parse(text = x, srcfile = src) :
 <text>:2:0: unexpected end of input
1: mean(x = c(1, 5, 10, 52)
  ^
Calls: <Anonymous> ... evaluate -> parse_all -> parse_all.character -> parse
Execution halted

Exited with status 1.
```

In this case, there needs to be one more parenthesis added at the end of your call to mean:

`mean(x = c(1, 5, 10, 52))`

**5. General guidelines**

Try your best to not be intimidated by R errors. Oftentimes, you will find that you are able to understand what they mean by carefully reading over them. When you can’t, carefully look over your R Markdown file again. You might also want to clear out all of your R environment and start at the top by running the chunks. Remember to only include what you deem your reader will need to follow your analysis.

Even people who have worked with R and programmed for years still use Google and support websites like Stack Overflow to ask for help with their R errors or when they aren’t sure how to do something in R. I think you’ll be pleasantly surprised at just how much support is available.

### INTERACT Tasks

##### CCHS Data
1. Read in the data `cchs.csv` (use `read_csv`)
2. Quickly view the first 10 rows of data (use `head`)
3. Display the type of variable for all variables in the dataset 
4. Create a scatterplot on height and weight (use `ggplot2`)
5. Clean the height and weight data so missing data coded as numbers (a common SPSS practice) become *NA* in R (use `forcats`)
6. Create a new scatterplot on height and weight with the clean data  (use `ggplot2`)
7. Recode BMI to represent weight categories from underweight to obese (use `forcats`)
8. Recode Province to include the province names instead of numbers 
9. Compute the mean and standard deviation of height and weight (use `dplyr::summarize`)
10. Compute the mean and standard deviation of height and weight based on Province. Then compute the mean and standard deviation of height and weight based on weight categories. (use `group_by` and `dplyr::summarize`)

##### Accel Data
1. Read in the 2 data files `accel.csv` (use `read_csv`)
2. Create a new variable that indicates participante 1 and participant 2
3. Append (stack) the 2 files together (use `dplyr::bind_rows`) 
4. Quickly view the first 10 rows of data (use `head`)
5. Display the type of variable for all variables in the dataset 
6. Create a scatterplot on x_axis and y_axis (use `ggplot2`)
7. Convert the time data to time format (use `lubridate`)
8. Compute the sum each of axis by second and by participant (use `group_by` and `dplyr::summarize`)
9. Compute the gravity subtracted vector magnitude `sqrt(x^2, y^2, z^2)-1` on the new data for each participant

## R Markdown

### Tutorial
https://www.youtube.com/watch?v=-apyD5f9nwg

https://www.rstudio.com/wp-content/uploads/2015/02/rmarkdown-cheatsheet.pdf

### INTERACT Tasks

## Database Connections in RStudio

### Tutorial

https://support.rstudio.com/hc/en-us/articles/214510788-Setting-up-R-to-connect-to-SQL-Server-

https://db.rstudio.com/rstudio/connections/

### INTERACT Tasks

These are the steps you will need to follow
1. Install PostgreSQL on your system. You can find the necessary files here (https://www.postgresql.org/download/)

You will now setup the connection to the server with the data. You will need to have USask credentials and VPN access to USask. If you have USask credentials you can find information on using the VPN here (https://www.usask.ca/ict/services/network-services/vpn/mac-106-intel-vpn.php). 

**Make sure you are connected to the USask VPN**



You will need to install the following libraries:
```
library(dbplyr)
library(odbc)
library(DBI)
library(RPostgreSQL) 
```    
Now create a connection to the server using the `dbConnect` function. Using the ` rstudioapi::askForPassword("Database user")` and `rstudioapi::askForPassword("Database password")` function allows you to share code without sharing the password. **Never store your password in code!**

```
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "interact_demo",
                host = "yakitori.usask.ca", port = 5432,
                user = rstudioapi::askForPassword("Database user"), 
                password = rstudioapi::askForPassword("Database password"))
```

We have provided you with a test username and test password for this tutorial. This will allow you to test the connect and make sure you can access the data. There is official INTERACT data here. 

The table names are accel_data and cchs. If you run this code and do not receive any error messages, this means that you have a connection. Now, if you run the code  `dbExistsTable(con, "cchs")`, it should respond with true. This means that you are properly connected, and can use the connection "con" to interact with the database. Once you have successfully connected, you can try out exploring the test database data. For instance, to load all the data from the cchs table, you would run `df_postgres <- dbGetQuery(con, "SELECT * from cchs")`. If you only wanted data with certain criteria, you could try a code such as `df_postgres <- dbGetQuery(con, "SELECT * from cchs where sdcgres > 5")`. 

If you have been working from RStudio's console, you can view your work by looking at the environment window in the top right corner. Click on the arrow beside `df_postgres`. 

### Additional INTERACT Tasks
2. Open the connection to the interact_demo database, then use `tbl()` to get a reference to each of the tables in it.
3. View the first ten rows of each table.
4. Display rows from the cchs table where the data originates in Saskatchewan.
5. Display only the caseid column from the cchs table, where the data originates from Ontario.
6. Get the average BMI by province from the cchs table.
7. Using ggplot2, display a bar graph showing the average BMI by province


