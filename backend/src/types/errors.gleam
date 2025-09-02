import pog

pub type DBError {
  DBQueryError(pog.QueryError)
  DBNotFoundError
  DBValidationError(String)
}
