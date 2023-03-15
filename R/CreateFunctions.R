createCohortTable <- function(connection,
                              cdmDatabaseSchema,
                              writeDatabaseSchema,
                              cohortTable,
                              regimenTable,
                              keepSteroids,
                              useHemoncToPullDrugs,
                              addCustomDrugConceptIds,
                              customDrugConceptIds,
                              customConceptIdsToExcluse
                              ) {
  if(!useHemoncToPullDrugs) {
    if(keepSteroids) drugClassificationIdInput <- getIngredientsIdsWithSteroids() else drugClassificationIdInput <- getIngredientsIdsWithoutSteroids()
  } else {
    usethis::ui_info('Pulling drug concept ids from HemOnc')
    drugClassificationIdInput <- getHemoncIngredients(
      connection = connection,
      cdmDatabaseSchema = cdmDatabaseSchema,
      keepSteroids = keepSteroids
  )
    usethis::ui_info('Drug concept ids were collected ')
}
  if(addCustomDrugConceptIds) {
    drugClassificationIdInput <- c(drugClassificationIdInput, customDrugConceptIds)
  }
  drugClassificationIdInput <- setdiff(drugClassificationIdInput, customConceptIdsToExcluse)

  sql <- SqlRender::render(sql = readDbSql("CohortBuild.sql", connection@dbms),
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           writeDatabaseSchema = writeDatabaseSchema,
                           cohortTable = cohortTable,
                           regimenTable = regimenTable,
                           drugClassificationIdInput = drugClassificationIdInput
                           )

  DatabaseConnector::executeSql(connection = connection, sql = sql)
}

createRegimenCalculation <- function(connection,
                                     writeDatabaseSchema,
                                     regimenTable,
                                     dateLagInput
) {
  sql <- SqlRender::render(sql = readDbSql("RegimenCalculation.sql", connection@dbms),
                           writeDatabaseSchema = writeDatabaseSchema,
                           regimenTable = regimenTable,
                           dateLagInput= dateLagInput)
  DatabaseConnector::executeSql(connection = connection, sql = sql)


}


createRawEvents <- function(connection,
                            rawEventTable,
                            cancerConceptId,
                            writeDatabaseSchema ,
                            cdmDatabaseSchema,
                            dateLagInput,
                            generateRawEvents){

  if(generateRawEvents) {
    drugClassificationIdInput <- getIngredientsIds()

    sql <- SqlRender::render(sql = readDbSql("RawEvents.sql", connection@dbms),
                            rawEventTable = rawEventTable,
                            cancerConceptId = cancerConceptId,
                            writeDatabaseSchema = writeDatabaseSchema,
                            cdmDatabaseSchema = cdmDatabaseSchema,
                            drugClassificationIdInput = drugClassificationIdInput$V1,
                            dateLagInput = dateLagInput)

    DatabaseConnector::executeSql(connection = connection, sql = sql)

  }
}
createVocabulary <- function(connection,
                             connectionDetails,
                             writeDatabaseSchema,
                             cdmDatabaseSchema,
                             vocabularyTable,
                             generateVocabTable
                             ) {

  if(generateVocabTable) {
    if(connectionDetails$dbms %in% c('postgresql', 'redshift')) {
  vocabTbl <- suppressWarnings(vocabularyTablesToInsert(
    connectionDetails = connectionDetails,
    writeDatabaseSchema = writeDatabaseSchema,
    cdmDatabaseSchema = cdmDatabaseSchema
  ))
  DatabaseConnector::insertTable(
    connection = connection,
    databaseSchema = writeDatabaseSchema,
    tableName = vocabularyTable,
    data = vocabTbl
  )
    } else {
  sql <- SqlRender::render(sql = readDbSql("RegimenVocabulary.sql", connection@dbms),
                           writeDatabaseSchema = writeDatabaseSchema,
                           cdmDatabaseSchema = cdmDatabaseSchema,
                           vocabularyTable = vocabularyTable)

  DatabaseConnector::executeSql(connection = connection, sql = sql)
    }
  } else {

    ParallelLogger::logInfo("Vocabulary will not be created")

  }
}


createRegimenFormatTable <- function(connection,
                                     writeDatabaseSchema,
                                     cohortTable,
                                     regimenTable,
                                     regimenIngredientTable,
                                     vocabularyTable,
                                     generateVocabTable
                                     ) {
  if(generateVocabTable) {
    sql_t <- readDbSql("RegimenFormat.sql", connection@dbms)
  } else {
    sql_t <- readDbSql("RegimenFormatWithoutVocabulary.sql", connection@dbms)
  }
  sql <- SqlRender::render(sql = sql_t,
                               writeDatabaseSchema = writeDatabaseSchema,
                               cohortTable = cohortTable,
                               regimenTable = regimenTable,
                               regimenIngredientTable = regimenIngredientTable,
                               vocabularyTable = vocabularyTable,
                           warnOnMissingParameters = FALSE
                               )

  DatabaseConnector::executeSql(connection = connection, sql = sql)

}



