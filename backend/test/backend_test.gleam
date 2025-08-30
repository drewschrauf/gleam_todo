import gleam/erlang/process
import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import pog
import router
import shared/task
import task/sql
import web
import wisp/testing
import youid/uuid

pub fn main() -> Nil {
  gleeunit.main()
}

fn with_context(next: fn(web.Context) -> a) -> a {
  let name = process.new_name("database")

  let assert Ok(config) =
    pog.url_config(name, "postgres://postgres:postgres@localhost:5555/postgres")
  let assert Ok(_) = config |> pog.start()
  let connection = pog.named_connection(name)

  let assert Ok(_) = pog.execute(pog.query("TRUNCATE TABLE tasks"), connection)

  next(web.Context(db: connection))
}

pub fn get_all_test() {
  use context <- with_context()

  let assert Ok(_) = sql.insert_task(context.db, "Buy milk")
  let assert Ok(_) = sql.insert_task(context.db, "Buy eggs")

  let assert Ok(tasks) =
    testing.get("/tasks", [])
    |> router.handle_request(context)
    |> testing.string_body()
    |> json.parse(task.task_list_decoder())

  tasks |> list.length() |> should.equal(2)
}

pub fn insert_test() {
  use context <- with_context()

  let response =
    testing.post_json(
      "/tasks",
      [],
      json.object([#("description", json.string("Buy milk"))]),
    )
    |> router.handle_request(context)

  response.status |> should.equal(200)

  let assert Ok(tasks) = sql.get_all_tasks(context.db)
  tasks.rows |> list.length() |> should.equal(1)
  let assert Ok(task) = tasks.rows |> list.first()
  task.description |> should.equal("Buy milk")
  task.done |> should.equal(False)
}

pub fn update_test() {
  use context <- with_context()

  let assert Ok(returned) = sql.insert_task(context.db, "Buy milk")
  let assert Ok(returned_task) = returned.rows |> list.first()

  let response =
    testing.post_json(
      "/tasks/" <> returned_task.id |> uuid.to_string(),
      [],
      task.Task(
        id: returned_task.id |> uuid.to_string(),
        description: "Buy eggs",
        done: True,
      )
        |> task.task_to_json(),
    )
    |> router.handle_request(context)

  response.status |> should.equal(200)

  let assert Ok(task) =
    response
    |> testing.string_body()
    |> json.parse(task.task_decoder())

  task.description |> should.equal("Buy eggs")
  task.done |> should.equal(True)

  let assert Ok(tasks) = sql.get_all_tasks(context.db)
  let assert Ok(task) = tasks.rows |> list.first()
  task.description |> should.equal("Buy eggs")
  task.done |> should.equal(True)
}

// pub fn update_not_found_test() {
//   use context <- with_context()
//
//   let id = uuid.v7() |> uuid.to_string()
//
//   let response =
//     testing.post_json(
//       "/tasks/" <> id,
//       [],
//       task.Task(id:, description: "Buy eggs", done: True)
//         |> task.task_to_json(),
//     )
//     |> router.handle_request(context)
//
//   response.status |> should.equal(404)
// }

pub fn update_id_mismatch_test() {
  use context <- with_context()

  let assert Ok(returned) = sql.insert_task(context.db, "Buy milk")
  let assert Ok(returned_task) = returned.rows |> list.first()

  let response =
    testing.post_json(
      "/tasks/" <> returned_task.id |> uuid.to_string(),
      [],
      task.Task(
        id: uuid.v7() |> uuid.to_string(),
        description: "Buy eggs",
        done: True,
      )
        |> task.task_to_json(),
    )
    |> router.handle_request(context)

  response.status |> should.equal(400)
}

pub fn insert_validation_test() {
  use context <- with_context()

  let response =
    testing.post_json(
      "/tasks",
      [],
      json.object([#("description", json.int(1))]),
    )
    |> router.handle_request(context)

  response.status |> should.equal(400)
}

pub fn delete_test() {
  use context <- with_context()

  let assert Ok(tasks) = sql.insert_task(context.db, "Buy milk")
  let assert Ok(task) = tasks.rows |> list.first()

  let _ =
    testing.delete("/tasks/" <> uuid.to_string(task.id), [], "")
    |> router.handle_request(context)

  let assert Ok(tasks) = sql.get_all_tasks(context.db)
  tasks.rows |> should.equal([])
}
