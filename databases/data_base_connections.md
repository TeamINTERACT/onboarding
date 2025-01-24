---
title: "Databases and Compute Canada"
author: "Daniel Fuller, Benoit Thierry"
date: "2025-01-24"
output:
  html_document:
    keep_md: yes
---

### Tutorial

https://support.rstudio.com/hc/en-us/articles/214510788-Setting-up-R-to-connect-to-SQL-Server-

https://db.rstudio.com/rstudio/connections/

### Prerequisites

These are the steps you will need to follow

1. Install PostgreSQL on your system. You can find the necessary files [here](https://www.postgresql.org/download/) (_NB:_ you may need to add the path to the PostgreSQL bin to your system PATH env variable)
2. Install pgAdmin on your system (optional). You can find the necessary files [here](https://www.pgadmin.org/download/)
3. Check that you have a SSH client installed; if not Install the latest version of Microsoft PowerShell (which includes a ssh client). You can find the necessary files [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
  
You will now setup the connection to the server with the data. You will need to have Compute Canada credentials and a SSH client (included with PowerShell).

### Connecting to CC database

In order to access the CC database and work locally with the data, you will need to open a SSH tunnel that will map the remote database to a local address on your computer (more details can be found on [CC Wiki](https://docs.alliancecan.ca/wiki/SSH_tunnelling)). From a PowerShell or another Shell on UNIX flavored OSes, create the SSH tunnel:

```sh
ssh -L 5433:cedar-pgsql-vm.int.cedar.computecanada.ca:5432 <YOUR_CC_USERNAME>@cedar.computecanada.ca 
```

This will let you access the CC database cluster from your computer at the address `localhost:5433`. (You can use another port instead of `5433` if this one is already in use.) **The shell from which the ssh tunnel has been opened needs to stay open for the duration of your database work.**

Once the SSH tunnel created, you can access the `interact_db` target database using standard pg clients from your computer, _e.g._ `psql` or pgAdmin. For instance, you can type the following command in a second shell on your computer:

```sh
psql -U <YOUR_CC_USERNAME> -h localhost -p 5433 interact_db
```

(_NB._ The `psql` command issued on a CC node is different, more can be found on [CC wiki](https://docs.alliancecan.ca/wiki/Database_servers#Cedar_PostgreSQL_server).)

Note that once the SSH tunnel has been established, you will no longer have to provide your password, nor save it somewhere in your script as all users logged on CC are automatically authenticated on the database cluster.

This method allows to retrieve the latest version of the survey datasets (corresponding Github hash indicated in the schema's comments/description, see below), while avoiding to store any data on the local drive _as long as you don't save the RData environment when closing R/Rstudio_.

#### Listing the data available

Interact surveys are stored under three schemas (_i.e._ DB equivalent of folders, see [definition](https://www.postgresql.org/docs/16/glossary.html#GLOSSARY-SCHEMA)) named `tk_survey`, `tk_survey2` and `tk_survey3`:

```
interact_db=>\dn+ tk_survey*
                                   List of schemas
    Name    |                                 Description
------------+-----------------------------------------------------------------------
 tk_survey  | Stores wave 1 survey data from Treksoft as well as reformatting views
 tk_survey2 | Stores wave 2 survey data from Treksoft as well as reformatting views
 tk_survey3 | Stores wave 3 survey data from Treksoft as well as reformatting views
(3 rows)
```

Within each schema, data is organized in materialized views (see [definition](https://www.postgresql.org/docs/16/glossary.html#GLOSSARY-MATERIALIZED-VIEW)) with names expressing the survey type (`eligibility`, `health`, `veritas`), the city (`mtl`, `skt`, `van`, `vic`) prefixed with the wave number and the subcategory of data extracted from the survey (`main` or other subcategories, depending on the survey type). From wave 2 on, returning and new participants have separate materialized views, with a `new` suffix appended to names of materialized views of new participants.

To illustrate the naming convention above, here is a few examples of materialized views and their explanation (note that materialized views need to be prefixed with the schema they belong to):

- `tk_survey2.eligibility_2mtl_main`: Eligibility questionnaire for returning participants in Montréal, wave 2
- `tk_survey2.eligibility_2mtlnew_main`: Eligibility questionnaire for new participants in Montréal, wave 2
- `tk_survey2.veritas_2skt_location`: Locations (points) extracted from the VERITAS questionnaire of returning participants in Saskatoon, wave 2
- `tk_survey2.health_2vicnew_main`: Health questionnaire for new participants in Victoria, wave 2

In addition to the survey data, researchers have access to the _essence tables_, located in the `essence_table` schema which contains the following tables:

```
interact_db=> \dt essence_table.*
                   List of relations
    Schema     |           Name           | Type  
---------------+--------------------------+-------
 essence_table | essence_activity_space   | table 
 essence_table | essence_health           | table 
 essence_table | essence_naud_social      | table 
 essence_table | essence_neighborhood500m | table 
 essence_table | essence_perchoux_tbx     | table 
(5 rows)
```

These tables comprise a selection of the most commonly used INTERACT variables combined with a series of derived variables for participants from all cities and waves, see [data dictionary](https://teaminteract.ca/ressources/INTERACT_datadict.html#essence_title) for more info. The `essence_neighborhood500m` contains the 500m network buffers used to derive some of the spatial indicators.

### Getting the data

#### Using R

In order to access the Interact data from _R_, you will need to install the following libraries:

```r
library(DBI)
library(RPostgres) 
```    

Then, to access the database, you need to create a connection object in R:

```r
con <- dbConnect(Postgres(), host="localhost", port=5433, user = "<YOUR_CC_USERNAME>", dbname = "interact_db")
```

Then, using the `con` object, it is possible to get the data from one materialized view, for instance:

```r
elig2mtl <- dbReadTable(con, Id(schema = "tk_survey2", table = "eligibility_2mtl_main"))
```

It is also possible to carve your own query:

```r
age2mtl <- dbGetQuery(con, "SELECT interact_id, age FROM tk_survey2.health_2mtl_main UNION SELECT interact_id, age FROM tk_survey2.health_2mtlnew_main")
```

When working in R Markdown, it is possible to leverage the multiple code languages recognized by Rmd to directly retrieve data from the database using SQL queries and have the resulting data stored in a DataFrame:


```` default
```{sql, connection=con, output.var="health1mtl"}
SELECT * FROM tk_survey.health_1mtl_main
```
````

Spatial data can also be read directly into R using `sf` package:

```r
library(sf)

veritas_locs <- st_read(con, layer = Id(schema = "tk_survey", table = "veritas_1mtl_location"))
```

#### Using Python

The prefered mode to access the data stored in the pg database relies on [`pandas`](https://pandas.pydata.org/):

```python
import pandas as pd
from sqlalchemy import create_engine

# Create SQLAlchemy connection engine
engine = create_engine("postgresql+psycopg2://<YOUR_CC_USERNAME>:@localhost:5433/interact_db")

# Get the data
df = pd.read_sql("SELECT * FROM tk_survey2.health_2mtl_main", engine)
print(df)
```

# Available data in Cedar database

## Survey data

All survey data is grouped under `tk_survey*` schemas, one schema per wave. The formatted answers, extracted from the 
completed surveys, is published in materialized views within each schema. Names are built from type of survey, wave, 
city and participant's status (new (`"new"`) / returning (`""`)).

VERITAS survey encompasses several types of data that are extracted from the main questionnaire, namely regularly 
visited locations, social network (individuals and groups) and the links between those entities.

- [Eligibility survey](https://teaminteract.ca/ressources/INTERACT_datadict.html#eligibility_questionnaire_title):
  - Main questionnaire template name: `eligibility_<WAVE><CITY><STATUS>_main`
    ```
      Schema   |           Name           
    -----------+--------------------------
    tk_survey  | eligibility_1mtl_main    
    tk_survey  | eligibility_1skt_main    
    tk_survey  | eligibility_1van_main    
    tk_survey  | eligibility_1vic_main    
    -----------+--------------------------
    tk_survey2 | eligibility_2mtl_main    
    tk_survey2 | eligibility_2mtlnew_main 
    tk_survey2 | eligibility_2skt_main    
    tk_survey2 | eligibility_2sktnew_main 
    tk_survey2 | eligibility_2van_main    
    tk_survey2 | eligibility_2vannew_main 
    tk_survey2 | eligibility_2vic_main    
    tk_survey2 | eligibility_2vicnew_main 
    -----------+--------------------------
    tk_survey3 | eligibility_3mtl_main    
    tk_survey3 | eligibility_3mtlnew_main 
    tk_survey3 | eligibility_3skt_main    
    tk_survey3 | eligibility_3sktnew_main 
    tk_survey3 | eligibility_3van_main    
    tk_survey3 | eligibility_3vannew_main 
    tk_survey3 | eligibility_3vic_main    
    tk_survey3 | eligibility_3vicnew_main 
    -----------+--------------------------
    tk_survey4 | eligibility_4mtl_main    
    tk_survey4 | eligibility_4mtlnew_main 
    tk_survey4 | eligibility_4skt_main    
    tk_survey4 | eligibility_4sktnew_main 
    tk_survey4 | eligibility_4van_main    
    tk_survey4 | eligibility_4vannew_main 
    tk_survey4 | eligibility_4vic_main    
    tk_survey4 | eligibility_4vicnew_main   
    ```
- [Health survey](https://teaminteract.ca/ressources/INTERACT_datadict.html#health_questionnaire_title):
  - Main questionnaire template name: `health_<WAVE><CITY><STATUS>_main`
    ```
      Schema   |        Name        
    -----------+---------------------
    tk_survey  | health_1mtl_main    
    tk_survey  | health_1skt_main    
    tk_survey  | health_1van_main    
    tk_survey  | health_1vic_main    
    tk_survey2 | health_2mtl_main    
    tk_survey2 | health_2mtlnew_main 
    tk_survey2 | health_2skt_main    
    tk_survey2 | health_2sktnew_main 
    tk_survey2 | health_2van_main    
    tk_survey2 | health_2vannew_main 
    tk_survey2 | health_2vic_main    
    tk_survey2 | health_2vicnew_main 
    tk_survey3 | health_3mtl_main    
    tk_survey3 | health_3mtlnew_main 
    tk_survey3 | health_3skt_main    
    tk_survey3 | health_3sktnew_main 
    tk_survey3 | health_3van_main    
    tk_survey3 | health_3vannew_main 
    tk_survey3 | health_3vic_main    
    tk_survey3 | health_3vicnew_main 
    tk_survey4 | health_4mtl_main    
    tk_survey4 | health_4mtlnew_main 
    tk_survey4 | health_4skt_main    
    tk_survey4 | health_4sktnew_main 
    tk_survey4 | health_4van_main    
    tk_survey4 | health_4vannew_main 
    tk_survey4 | health_4vic_main    
    tk_survey4 | health_4vicnew_main 
    ```
  - Children questionnaire template name: `health_<WAVE><CITY><STATUS>_children`; contains a variable number of records 
    for participants who declared living with children
    ```
      Schema   |          Name           
    -----------+-------------------------
    tk_survey  | health_1mtl_children    
    tk_survey  | health_1skt_children    
    tk_survey  | health_1van_children    
    tk_survey  | health_1vic_children    
    tk_survey2 | health_2mtl_children    
    tk_survey2 | health_2mtlnew_children 
    tk_survey2 | health_2skt_children    
    tk_survey2 | health_2sktnew_children 
    tk_survey2 | health_2van_children    
    tk_survey2 | health_2vannew_children 
    tk_survey2 | health_2vic_children    
    tk_survey2 | health_2vicnew_children 
    tk_survey3 | health_3mtl_children    
    tk_survey3 | health_3mtlnew_children 
    tk_survey3 | health_3skt_children    
    tk_survey3 | health_3sktnew_children 
    tk_survey3 | health_3van_children    
    tk_survey3 | health_3vannew_children 
    tk_survey3 | health_3vic_children    
    tk_survey3 | health_3vicnew_children 
    tk_survey4 | health_4mtl_children    
    tk_survey4 | health_4mtlnew_children 
    tk_survey4 | health_4skt_children    
    tk_survey4 | health_4sktnew_children 
    tk_survey4 | health_4van_children    
    tk_survey4 | health_4vannew_children 
    tk_survey4 | health_4vic_children    
    tk_survey4 | health_4vicnew_children 
    ```
- [VERITAS survey](https://teaminteract.ca/ressources/INTERACT_datadict.html#veritas_questionnaire_title):
  - Main questionnaire template name:  `veritas_<WAVE><CITY><STATUS>_main`
    ```
      Schema   |         Name         
    -----------+----------------------
    tk_survey  | veritas_1mtl_main    
    tk_survey  | veritas_1skt_main    
    tk_survey  | veritas_1van_main    
    tk_survey  | veritas_1vic_main    
    tk_survey2 | veritas_2mtl_main    
    tk_survey2 | veritas_2mtlnew_main 
    tk_survey2 | veritas_2skt_main    
    tk_survey2 | veritas_2sktnew_main 
    tk_survey2 | veritas_2van_main    
    tk_survey2 | veritas_2vannew_main 
    tk_survey2 | veritas_2vic_main    
    tk_survey2 | veritas_2vicnew_main 
    tk_survey3 | veritas_3mtl_main    
    tk_survey3 | veritas_3mtlnew_main 
    tk_survey3 | veritas_3skt_main    
    tk_survey3 | veritas_3sktnew_main 
    tk_survey3 | veritas_3van_main    
    tk_survey3 | veritas_3vannew_main 
    tk_survey3 | veritas_3vic_main    
    tk_survey3 | veritas_3vicnew_main 
    tk_survey4 | veritas_4mtl_main    
    tk_survey4 | veritas_4mtlnew_main 
    tk_survey4 | veritas_4skt_main    
    tk_survey4 | veritas_4sktnew_main 
    tk_survey4 | veritas_4van_main    
    tk_survey4 | veritas_4vannew_main 
    tk_survey4 | veritas_4vic_main    
    tk_survey4 | veritas_4vicnew_main 
    ```
  - [Veritas entities](https://teaminteract.ca/ressources/INTERACT_datadict.html#veritas_entity_title):
    - Veritas location template name: `veritas_<WAVE><CITY><STATUS>_location`
      ```
        Schema   |         Name         
      -----------+----------------------
      tk_survey  | veritas_1mtl_location    
      tk_survey  | veritas_1skt_location    
      tk_survey  | veritas_1van_location    
      tk_survey  | veritas_1vic_location    
      tk_survey2 | veritas_2mtl_location    
      tk_survey2 | veritas_2mtlnew_location 
      tk_survey2 | veritas_2skt_location    
      tk_survey2 | veritas_2sktnew_location 
      tk_survey2 | veritas_2van_location    
      tk_survey2 | veritas_2vannew_location 
      tk_survey2 | veritas_2vic_location    
      tk_survey2 | veritas_2vicnew_location 
      tk_survey3 | veritas_3mtl_location    
      tk_survey3 | veritas_3mtlnew_location 
      tk_survey3 | veritas_3skt_location    
      tk_survey3 | veritas_3sktnew_location 
      tk_survey3 | veritas_3van_location    
      tk_survey3 | veritas_3vannew_location 
      tk_survey3 | veritas_3vic_location    
      tk_survey3 | veritas_3vicnew_location 
      tk_survey4 | veritas_4mtl_location    
      tk_survey4 | veritas_4mtlnew_location 
      tk_survey4 | veritas_4skt_location    
      tk_survey4 | veritas_4sktnew_location 
      tk_survey4 | veritas_4van_location    
      tk_survey4 | veritas_4vannew_location 
      tk_survey4 | veritas_4vic_location    
      tk_survey4 | veritas_4vicnew_location 
      ```
    - Veritas area template name: `veritas_<WAVE><CITY><STATUS>_poly_geom`: stores perceived residential neighborhood, 
      area of improvement and area of deterioration
      ```
        Schema   |           Name            
      -----------+---------------------------
      tk_survey  | veritas_1mtl_poly_geom    
      tk_survey  | veritas_1skt_poly_geom    
      tk_survey  | veritas_1van_poly_geom    
      tk_survey  | veritas_1vic_poly_geom    
      tk_survey2 | veritas_2mtl_poly_geom    
      tk_survey2 | veritas_2mtlnew_poly_geom 
      tk_survey2 | veritas_2skt_poly_geom    
      tk_survey2 | veritas_2sktnew_poly_geom 
      tk_survey2 | veritas_2van_poly_geom    
      tk_survey2 | veritas_2vannew_poly_geom 
      tk_survey2 | veritas_2vic_poly_geom    
      tk_survey2 | veritas_2vicnew_poly_geom 
      tk_survey3 | veritas_3vic_poly_geom    
      tk_survey3 | veritas_3vicnew_poly_geom 
      ```
    - Veritas social contact|individual template name: `veritas_<WAVE><CITY><STATUS>_people`
      ```
        Schema   |               Name               
      -----------+-----------------------
      tk_survey  | veritas_1mtl_people              
      tk_survey  | veritas_1skt_people              
      tk_survey  | veritas_1van_people              
      tk_survey  | veritas_1vic_people              
      -----------+-----------------------
      tk_survey2 | veritas_2mtl_people              
      tk_survey2 | veritas_2mtlnew_people           
      tk_survey2 | veritas_2skt_people              
      tk_survey2 | veritas_2sktnew_people           
      tk_survey2 | veritas_2van_people              
      tk_survey2 | veritas_2vannew_people           
      tk_survey2 | veritas_2vic_people              
      tk_survey2 | veritas_2vicnew_people           
      -----------+-----------------------
      tk_survey3 | veritas_3mtl_people              
      tk_survey3 | veritas_3mtlnew_people           
      tk_survey3 | veritas_3skt_people              
      tk_survey3 | veritas_3sktnew_people           
      tk_survey3 | veritas_3van_people              
      tk_survey3 | veritas_3vannew_people           
      tk_survey3 | veritas_3vic_people              
      tk_survey3 | veritas_3vicnew_people           
      ```
    - Veritas social contact|group template name: `veritas_<WAVE><CITY><STATUS>_group`
      ```
        Schema   |               Name               
      -----------+-----------------------
      tk_survey  | veritas_1mtl_people              
      tk_survey  | veritas_1skt_people              
      tk_survey  | veritas_1van_people              
      tk_survey  | veritas_1vic_people              
      -----------+-----------------------
      tk_survey2 | veritas_2mtl_people              
      tk_survey2 | veritas_2mtlnew_people           
      tk_survey2 | veritas_2skt_people              
      tk_survey2 | veritas_2sktnew_people           
      tk_survey2 | veritas_2van_people              
      tk_survey2 | veritas_2vannew_people           
      tk_survey2 | veritas_2vic_people              
      tk_survey2 | veritas_2vicnew_people           
      -----------+-----------------------
      tk_survey3 | veritas_3mtl_people              
      tk_survey3 | veritas_3mtlnew_people           
      tk_survey3 | veritas_3skt_people              
      tk_survey3 | veritas_3sktnew_people           
      tk_survey3 | veritas_3van_people              
      tk_survey3 | veritas_3vannew_people           
      tk_survey3 | veritas_3vic_people              
      tk_survey3 | veritas_3vicnew_people           
      ```
    - Veritas social entity relationship template name: `veritas_<WAVE><CITY><STATUS>_relationship`: stores links between 
      locations and social contact and among social contact
      ```
        Schema   |         Name          
      -----------+-----------------------
      tk_survey  | veritas_1mtl_group    
      tk_survey  | veritas_1skt_group    
      tk_survey  | veritas_1van_group    
      tk_survey  | veritas_1vic_group    
      -----------+-----------------------
      tk_survey2 | veritas_2mtl_group    
      tk_survey2 | veritas_2mtlnew_group 
      tk_survey2 | veritas_2skt_group    
      tk_survey2 | veritas_2sktnew_group 
      tk_survey2 | veritas_2van_group    
      tk_survey2 | veritas_2vannew_group 
      tk_survey2 | veritas_2vic_group    
      tk_survey2 | veritas_2vicnew_group 
      -----------+-----------------------
      tk_survey3 | veritas_3vic_group    
      tk_survey3 | veritas_3vicnew_group 
      ```
    - Veritas social contact proximity:
      - Important people template name: `veritas_<WAVE><CITY><STATUS>_important_people`
        ```
          Schema   |               Name               
        -----------+----------------------------------
        tk_survey  | veritas_1mtl_important_people    
        tk_survey  | veritas_1skt_important_people    
        tk_survey  | veritas_1van_important_people    
        tk_survey  | veritas_1vic_important_people    
        tk_survey2 | veritas_2mtl_important_people    
        tk_survey2 | veritas_2mtlnew_important_people 
        tk_survey2 | veritas_2skt_important_people    
        tk_survey2 | veritas_2sktnew_important_people 
        tk_survey2 | veritas_2van_important_people    
        tk_survey2 | veritas_2vannew_important_people 
        tk_survey2 | veritas_2vic_important_people    
        tk_survey2 | veritas_2vicnew_important_people 
        tk_survey3 | veritas_3mtl_important_people    
        tk_survey3 | veritas_3mtlnew_important_people 
        tk_survey3 | veritas_3skt_important_people    
        tk_survey3 | veritas_3sktnew_important_people             
        tk_survey3 | veritas_3van_important_people    
        tk_survey3 | veritas_3vannew_important_people 
        tk_survey3 | veritas_3vic_important_people    
        tk_survey3 | veritas_3vicnew_important_people 
        ```
      - People socializing with participant template name: `veritas_<WAVE><CITY><STATUS>_socialize_people`
        ```
          Schema   |               Name               
        -----------+----------------------------------
        tk_survey  | veritas_1mtl_socialize_people    
        tk_survey  | veritas_1skt_socialize_people    
        tk_survey  | veritas_1van_socialize_people    
        tk_survey  | veritas_1vic_socialize_people    
        tk_survey2 | veritas_2mtl_socialize_people    
        tk_survey2 | veritas_2mtlnew_socialize_people 
        tk_survey2 | veritas_2skt_socialize_people    
        tk_survey2 | veritas_2sktnew_socialize_people 
        tk_survey2 | veritas_2van_socialize_people    
        tk_survey2 | veritas_2vannew_socialize_people 
        tk_survey2 | veritas_2vic_socialize_people    
        tk_survey2 | veritas_2vicnew_socialize_people 
        tk_survey3 | veritas_3mtl_socialize_people    
        tk_survey3 | veritas_3mtlnew_socialize_people 
        tk_survey3 | veritas_3skt_socialize_people    
        tk_survey3 | veritas_3sktnew_socialize_people 
        tk_survey3 | veritas_3van_socialize_people    
        tk_survey3 | veritas_3vannew_socialize_people 
        tk_survey3 | veritas_3vic_socialize_people    
        tk_survey3 | veritas_3vicnew_socialize_people 
        ```
      - People not so close to participant tempalte name: `veritas_<WAVE><CITY><STATUS>_not_close_people`
        ```
          Schema   |               Name               
        -----------+----------------------------------
        tk_survey  | veritas_1mtl_not_close_people    
        tk_survey  | veritas_1skt_not_close_people    
        tk_survey  | veritas_1van_not_close_people    
        tk_survey  | veritas_1vic_not_close_people    
        tk_survey2 | veritas_2mtl_not_close_people    
        tk_survey2 | veritas_2mtlnew_not_close_people 
        tk_survey2 | veritas_2skt_not_close_people    
        tk_survey2 | veritas_2sktnew_not_close_people 
        tk_survey2 | veritas_2van_not_close_people    
        tk_survey2 | veritas_2vannew_not_close_people 
        tk_survey2 | veritas_2vic_not_close_people    
        tk_survey2 | veritas_2vicnew_not_close_people 
        tk_survey3 | veritas_3vic_not_close_people    
        tk_survey3 | veritas_3vicnew_not_close_people 
        ```
      - People living with participant tempalte name: `veritas_<WAVE><CITY><STATUS>_household_people`
        ```
          Schema   |               Name               
        -----------+----------------------------------
        tk_survey3 | veritas_3mtl_household_people    
        tk_survey3 | veritas_3mtlnew_household_people 
        tk_survey3 | veritas_3skt_household_people    
        tk_survey3 | veritas_3sktnew_household_people 
        tk_survey3 | veritas_3van_household_people    
        tk_survey3 | veritas_3vannew_household_people 
        ```
    - Past residential addresses template name (Montréal only): `veritas_<WAVE>mtl<STATUS>_historical_address`
      ```
        Schema   |                Name                
      -----------+------------------------------------
      tk_survey  | veritas_1mtl_historical_address    
      tk_survey2 | veritas_2mtlnew_historical_address 
      tk_survey4 | veritas_4mtl_historical_address    
      tk_survey4 | veritas_4mtlnew_historical_address 
      ```

## Essence table

The [Essence Table](https://teaminteract.ca/ressources/INTERACT_datadict.html#essence_title) comprises a selection of the 
most commonly used INTERACT variables combined with a series of derived variables for participants from all cities and waves.
All variables have been harmonized across all cities and waves for easier comparison, hence some original variables might get
a slightly modified list of category options.

The essence table is stored in its proper `essence_table` schema. The variables are grouped under four thematic groups, each 
with its own table.

- `essence_health`: harmonized core health variables across all cities/waves
- `essence_activity_space`: basic aggregated statistics about the VERITAS locations
- `essence_perchoux_tbx`: aggregated statistics based on [Camille Perchoux's spatial metric toolbox](https://doi.org/10.1016/j.socscimed.2014.07.026)
- `essence_naud_social`: aggregated social network metrics based on [Alexandre Naud's toolbox](https://doi.org/10.1016/j.healthplace.2020.102454)
- `essence_neighborhood500m`: 500m network buffers around participant's home (polygons)

## Ecological Momentary Assessment (EMA)

[Ecological momentary assessment (EMA)](https://teaminteract.ca/ressources/INTERACT_datadict.html#ema_title) involves repeated sampling of the participants' wellbeing in real time, and in their 
natural environments. It relies on the EthicaApp running on the participants' smartphone to capture their responses to 
various prompts up to three times per day.

EMAs are stored in schemas `ema*`, one per wave, with each city having its own table: `mtl`, `skt`, `van` and `vic` within each scehma.

```
 Schema | Name 
--------+------
 ema    | mtl  
 ema    | skt  
 ema    | van  
 ema    | vic  
--------+------
 ema2   | mtl  
 ema2   | skt  
 ema2   | van  
 ema2   | vic  
--------+------
 ema3   | mtl  
 ema3   | skt  
 ema3   | van  
 ema3   | vic  
```

## Table of Power (ToP)

The tables of power store combined accelerometry and location data from SenseDoc (and eventually from Ethica) at 2 different 
epochs -- 1 minute and 1 second. Accelerometry is aggregagted at each level through Actigraph-like counts (see [ref](https://doi.org/10.1123/jmpb.2019-0063)).

SenseDoc ToPs are published in `top_sd*` schemas, one per wave, with each city and epoch stored in a separate table.

```
 Schema  |     Name     
---------+--------------
 top_sd  | top_1min_mtl 
 top_sd  | top_1min_skt 
 top_sd  | top_1min_van 
 top_sd  | top_1min_vic 
 top_sd  | top_1sec_mtl 
 top_sd  | top_1sec_skt 
 top_sd  | top_1sec_van 
 top_sd  | top_1sec_vic 
---------+--------------
 top_sd2 | top_1min_mtl 
 top_sd2 | top_1min_skt 
 top_sd2 | top_1min_van 
 top_sd2 | top_1min_vic 
 top_sd2 | top_1sec_mtl 
 top_sd2 | top_1sec_skt 
 top_sd2 | top_1sec_van 
 top_sd2 | top_1sec_vic 
---------+--------------
 top_sd3 | top_1min_mtl 
 top_sd3 | top_1min_skt 
 top_sd3 | top_1min_van 
 top_sd3 | top_1min_vic 
 top_sd3 | top_1sec_mtl 
 top_sd3 | top_1sec_skt 
 top_sd3 | top_1sec_van 
 top_sd3 | top_1sec_vic 
 ```
