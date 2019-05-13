---
title: "Databases and Compute Canada"
author: "Daniel Fuller"
date: "13/05/2019"
output:
  html_document:
    keep_md: yes
---

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


