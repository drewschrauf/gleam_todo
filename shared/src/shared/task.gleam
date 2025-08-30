import gleam/dynamic/decode
import gleam/json

pub type Task {
  Task(id: String, description: String, done: Bool)
}

pub fn task_list_to_json(task_list: List(Task)) {
  json.array(task_list, task_to_json)
}

pub fn task_to_json(task: Task) {
  json.object([
    #("id", json.string(task.id)),
    #("description", json.string(task.description)),
    #("done", json.bool(task.done)),
  ])
}

pub fn task_list_decoder() {
  decode.list(task_decoder())
}

pub fn task_decoder() {
  use id <- decode.field("id", decode.string)
  use description <- decode.field("description", decode.string)
  use done <- decode.field("done", decode.bool)
  decode.success(Task(id:, description:, done:))
}
