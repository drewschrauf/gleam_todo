pub type RemoteData(success, error) {
  NotRequested
  Loading
  Success(success)
  Failure(error)
}

pub fn map(remote_data: RemoteData(a, b), map: fn(a) -> a) {
  case remote_data {
    Success(data) -> Success(map(data))
    other -> other
  }
}
