#' Create an oncology drug regimen table in a `writeDatabaseSchema` database
#'
#' @description
#' Creates treatment regimens
#'
#' @param connectionDetails
#' @param writeDatabaseSchema
#' @param rawEventTable
#' @param dateLagInput
#' @param generateVocabTable
#' @param sampleSize
#' @param cdmDatabaseSchema
#' @param regimenIngredientTable
#' @param vocabularyTable
#' @param cancerConceptId
#' @param generateRawEvents
#' @param keepSteroids Boolean parameter if TRUE algorithm will look for steroids along other drugs
#' @param useHemoncToPullDrugs Boolean parameter if TRUE algorithm will use HemOnc vocabulary as a source of ingredients otherwise - internal csv
#' @param writeToEpisodeTable Boolean parameter if TRUE algorithm will delete form episode table with `episodeTypeConceptId` and insert `regimenIngredientTable` rows with `episodeTypeConceptId`
#' @param writeToEpisodeEventTable Boolean parameter if TRUE algorithm will delete form episode_event table with `episodeEventTableConceptId` and insert `regimenIngredientTable` rows with `episodeEventTableConceptId`
#' @param removeExclusion Boolean parameter if TRUE algorithm will not exclude supportive drugs
#' @param addCustomDrugConceptIds  Boolean parameter if TRUE algorithm will include custom concept_ids
#' @param customDrugConceptIds integer vector. IF addCustomDrugConceptIds TRUE - ids will be included to algorithm analysis
#' @param customConceptIdsToExcluse integer vector to remove ingredient ids from analysis
#' @return
#' This function does not return a value. It is called for its side effect of
#' creating a new SQL table called `regimenIngredientTable` in `writeDatabaseSchema`.
#' @export

createRegimens <- function(connectionDetails,
                           cdmDatabaseSchema,
                           writeDatabaseSchema,
                           cohortTable = 'ct_orf',
                           rawEventTable,
                           regimenTable = 'rt_orf',
                           regimenIngredientTable,
                           vocabularyTable,
                           cancerConceptId,
                           dateLagInput,
                           generateVocabTable,
                           generateRawEvents,
                           keepSteroids,
                           useHemoncToPullDrugs,
                           writeToEpisodeTable,
                           writeToEpisodeEventTable,
                           episodeTypeConceptId,
                           episodeEventTableConceptId,
                           addCustomDrugConceptIds,
                           customDrugConceptIds = c(),
                           customConceptIdsToExcluse = c()
                           ) {

  connection <-  DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  usethis::ui_info('Cohort and regimen tables creation')
  createCohortTable(connection = connection,
                    cdmDatabaseSchema = cdmDatabaseSchema,
                    writeDatabaseSchema = writeDatabaseSchema,
                    cohortTable = cohortTable,
                    regimenTable = regimenTable,
                    keepSteroids = keepSteroids,
                    useHemoncToPullDrugs = useHemoncToPullDrugs,
                    addCustomDrugConceptIds = addCustomDrugConceptIds,
                    customDrugConceptIds = customDrugConceptIds,
                    customConceptIdsToExcluse = customConceptIdsToExcluse
  )
  usethis::ui_info('Regimen Calculation')
  createRegimenCalculation(connection = connection,
                           writeDatabaseSchema = writeDatabaseSchema,
                           regimenTable = regimenTable,
                           dateLagInput= dateLagInput)

  createRawEvents(connection = connection,
                  rawEventTable = rawEventTable,
                  cancerConceptId = cancerConceptId,
                  writeDatabaseSchema = writeDatabaseSchema,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  dateLagInput = dateLagInput,
                  generateRawEvents = generateRawEvents)
  usethis::ui_info('Vocabulary creation')
  createVocabulary(connection = connection,
                   writeDatabaseSchema = writeDatabaseSchema,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   vocabularyTable = vocabularyTable,
                   generateVocabTable = generateVocabTable)
  usethis::ui_info('Regimen Formatting')
  createRegimenFormatTable(connection = connection,
                           writeDatabaseSchema = writeDatabaseSchema,
                           cohortTable = cohortTable,
                           regimenTable = regimenTable,
                           regimenIngredientTable = regimenIngredientTable,
                           vocabularyTable = vocabularyTable,
                           generateVocabTable = generateVocabTable
                           )


  if(isTRUE(writeToEpisodeTable)) {
    usethis::ui_info('Writing To Episode Table')
    writeToEpisodeTable(
      connection = connection,
      writeDatabaseSchema = writeDatabaseSchema,
      regimenIngredientTable = regimenIngredientTable,
      episodeTypeConceptId = episodeTypeConceptId,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  }

  if(writeToEpisodeEventTable) {
    usethis::ui_info('Writing To Episode Event Table')
    writeToEpisodeEventTable(
      connection = connection,
      writeDatabaseSchema = writeDatabaseSchema,
      regimenIngredientTable = regimenIngredientTable,
      episodeEventTableConceptId = episodeEventTableConceptId,
      cdmDatabaseSchema = cdmDatabaseSchema
    )
  }


}


#' @export
#'
#'
getHemoncIngredients <- function(
  connection,
  cdmDatabaseSchema,
  keepSteroids = FALSE
) {

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "FetchDrugConceptIds.sql",
    packageName = getThisPackageName(),
    cdmDatabaseSchema = cdmDatabaseSchema,
    commentSteroids = ifelse(keepSteroids, '--','')
  )
  DatabaseConnector::querySql(
    connection,
    sql = sql
    )$CONCEPT_ID_2
  }
