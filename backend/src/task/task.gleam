import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import pog
import task/sql
import youid/uuid.{type Uuid}

pub type Task {
  Task(id: Uuid, description: String, done: Bool)
}

pub fn task_list_to_json(task_list: List(Task)) {
  json.array(task_list, task_to_json)
}

pub fn task_to_json(task: Task) {
  json.object([
    #("id", json.string(task.id |> uuid.to_string())),
    #("description", json.string(task.description)),
    #("done", json.bool(task.done)),
  ])
}

pub fn make_task_list_decoder() {
  decode.list(make_task_decoder())
}

pub fn make_task_decoder() {
  use id <- decode.field("id", {
    decode.string
    |> decode.then(fn(s) {
      case uuid.from_string(s) {
        Ok(id) -> decode.success(id)
        Error(_) -> decode.failure(uuid.v7(), "ID isn't parseable as UUID")
      }
    })
  })
  use description <- decode.field("description", decode.string)
  use done <- decode.field("done", decode.bool)
  decode.success(Task(id:, description:, done:))
}

pub fn get_all_tasks(db: pog.Connection) -> Result(List(Task), String) {
  use returned <- result.try(
    sql.get_all_tasks(db)
    |> result.replace_error("Couldn't retrieve tasks from DB"),
  )

  returned.rows
  |> list.map(fn(row) {
    Task(id: row.id, description: row.description, done: row.done)
  })
  |> Ok()
}

pub fn insert_task(
  description: String,
  db: pog.Connection,
) -> Result(Task, String) {
  use returned <- result.try(
    sql.insert_task(db, description)
    |> result.replace_error("Couldn't insert task into DB"),
  )
  use row <- result.try(
    returned.rows
    |> list.first()
    |> result.replace_error("Insert didn't return an inserted record"),
  )
  Ok(Task(id: row.id, description: row.description, done: row.done))
}

pub fn update_task(task: Task, db: pog.Connection) -> Result(Task, String) {
  use returned <- result.try(
    sql.update_task(db, task.id, task.description, task.done)
    |> result.replace_error("Couldn't update task in DB"),
  )

  use row <- result.try(
    returned.rows
    |> list.first()
    |> result.replace_error("Update didn't return an inserted record"),
  )
  Ok(Task(id: row.id, description: row.description, done: row.done))
}

pub fn delete_task(id: Uuid, db: pog.Connection) -> Result(Bool, String) {
  use returned <- result.try(
    sql.delete_task(db, id)
    |> result.replace_error("Couldn't delete task from DB"),
  )
  Ok(returned.count == 1)
}
