readDbSql <- function(sql_filename, dbms) {
  supported_dbms <- c("postgresql", "redshift", "sqlite", "bigquery")
  if(!(dbms %in% supported_dbms)) {
    stop(paste(dbms, "is not a supported database. \nSupported dbms are", paste(supported_dbms, collapse = ", "), "."))
  }
  package <- getThisPackageName()
  path <- system.file("sql", dbms, sql_filename, package = package, mustWork = TRUE)
  SqlRender::readSql(path)
}

getThisPackageName <- function() {
  return("OncologyRegimenFinder")
}

getIngredientsIdsWithSteroids <- function(){
  path <- system.file("csv",
                      sql_filename = "withSteroids.csv",
                      package = getThisPackageName(),
                      mustWork = TRUE)
  read.csv(path)$concept_id_2
}

getIngredientsIdsWithoutSteroids <- function(){
  path <- system.file("csv",
                      sql_filename = "withoutSteroids.csv",
                      package = getThisPackageName(),
                      mustWork = TRUE)
  read.csv(path)$concept_id_2
}

getIngredientsWithoutExclusion <- function(){
  path <- system.file("csv",
                      sql_filename = "withSteroidsAndSuppoprtive.csv",
                      package = getThisPackageName(),
                      mustWork = TRUE)
  read.csv(path)$concept_id_2
}


