# *******************************************************
# -----------------INSTRUCTIONS -------------------------
# *******************************************************
#
#-----------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------
# This CodeToRun.R is provided as an example of how to run this package.
# Below you will find 2 sections: the 1st is for installing the dependencies
# required to run the study and the 2nd for running the package.
#
# The code below makes use of R environment variables (denoted by "Sys.getenv(<setting>)") to
# allow for protection of sensitive information. If you'd like to use R environment variables stored
# in an external file, this can be done by creating an .Renviron file in the root of the folder
# where you have cloned this code. For more information on setting environment variables please refer to:
# https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRenviron.html
#
#
# Below is an example .Renviron file's contents: (please remove)
# the "#" below as these too are interprted as comments in the .Renviron file:
#
#    DBMS = "postgresql"
#    DB_SERVER = "database.server.com"
#    DB_PORT = 5432
#    DB_USER = "database_user_name_goes_here"
#    DB_PASSWORD = "your_secret_password"
#    FFTEMP_DIR = "E:/fftemp"
#    CDM_SCHEMA = "your_cdm_schema"
#    COHORT_SCHEMA = "public"  # or other schema to write intermediate results to
#    PATH_TO_DRIVER = "/path/to/jdbc_driver"
#
# The following describes the settings
#    DBMS, DB_SERVER, DB_PORT, DB_USER, DB_PASSWORD := These are the details used to connect
#    to your database server. For more information on how these are set, please refer to:
#    http://ohdsi.github.io/DatabaseConnector/
#
#    FFTEMP_DIR = A directory where temporary files used by the FF package are stored while running.
#
#
# Once you have established an .Renviron file, you must restart your R session for R to pick up these new
# variables.
#
# In section 2 below, you will also need to update the code to use your site specific values. Please scroll
# down for specific instructions.
#-----------------------------------------------------------------------------------------------
#
#
# *******************************************************
# SECTION 1: Install the package and its dependencies (not needed if already done) -------------
# *******************************************************
# remotes::install_github("OHDSI/DatabaseConnector")
# library(DatabaseConnector)
# remotes::install_github("OHDSI/SqlRender")
# library(SqlRender)
# remotes::install_github("A1exanderAlexeyuk/OncologyRegimenFinder")
library(OncologyRegimenFinder)
  connectionDetails <- createConnectionDetails(
    dbms = "postgresql",
    server = Sys.getenv("DB_SERVER"),
    user = Sys.getenv("ohdsi_password"),
    password = Sys.getenv("ohdsi_password"),
    port = "5441"
  )
  conn <- connect(connectionDetails = connectionDetails)
writeDatabaseSchema <- "alex_alexeyuk_results"
cdmDatabaseSchema <- "cdm_531"
vocabularyTable <- "regimen_voc_upd2"
regimenIngredientTable <- "regimen_ingredient_table2"
rawEventTable <- NULL
keepSteroids <- FALSE # if TRUE corticosteroids will be added to analysis
useHemoncToPullDrugs <- TRUE # if TRUE drug concept_ids will be collected from HemOnc, otherwise from internal csv
writeToEpisodeTable <- FALSE # if TRUE delete where episode_type_concept_id = episodeTypeConceptId  (old records) and insert updated info
writeToEpisodeEventTable <- FALSE #if TRUE delete where episode_event_table_concept_id = episodeEventTableConceptId (old records) and insert       #updated info
generateVocabTable = TRUE #Boolean parameter if TRUE algorithm will create internal vocabulary to merge with ingredient table
addCustomDrugConceptIds <- FALSE #addCustomDrugConceptIds  Boolean parameter if TRUE algorithm will include custom concept_ids
customDrugConceptIds <- c() #integer vector. IF addCustomDrugConceptIds TRUE - ids will be included to algorithm analysis
customConceptIdsToExcluse <- c() #integer vector to exclude from analysis
OncologyRegimenFinder::createRegimens(
    connectionDetails,
    cdmDatabaseSchema,
    cohortTable = 'ct_orf',
    regimenTable = 'rt_orf',
    writeDatabaseSchema,
    rawEventTable,
    regimenIngredientTable,
    vocabularyTable,
    cancerConceptId = 4115276,
    dateLagInput = 30,
    generateVocabTable,
    generateRawEvents = FALSE,
    keepSteroids,
    useHemoncToPullDrugs = TRUE,
    episodeTypeConceptId = 32545,
    episodeEventTableConceptId = 1147094,
    writeToEpisodeTable,
    writeToEpisodeEventTable,
    addCustomDrugConceptIds = FALSE,
    customDrugConceptIds = c(),
    customConceptIdsToExcluse  = c()
)
