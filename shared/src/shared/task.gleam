import gleam/dynamic/decode
import gleam/json
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}

pub type Task {
  Task(id: String, description: String, done: Bool, created_at: Timestamp)
}

pub fn task_list_to_json(task_list: List(Task)) {
  json.array(task_list, task_to_json)
}

pub fn task_to_json(task: Task) {
  json.object([
    #("id", json.string(task.id)),
    #("description", json.string(task.description)),
    #("done", json.bool(task.done)),
    #(
      "created_at",
      json.string(task.created_at |> timestamp.to_rfc3339(calendar.utc_offset)),
    ),
  ])
}

pub fn task_list_decoder() {
  decode.list(task_decoder())
}

pub fn task_decoder() {
  use id <- decode.field("id", decode.string)
  use description <- decode.field("description", decode.string)
  use done <- decode.field("done", decode.bool)
  use created_at <- decode.field(
    "created_at",
    decode.string
      |> decode.then(fn(date) {
        case timestamp.parse_rfc3339(date) {
          Ok(timestamp) -> decode.success(timestamp)
          Error(_) ->
            decode.failure(timestamp.system_time(), "Couldn't parse date")
        }
      }),
  )
  decode.success(Task(id:, description:, done:, created_at:))
}
