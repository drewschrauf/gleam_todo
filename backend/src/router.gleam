import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/string_tree
import shared/task
import task/task as task_db
import web.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub fn handle_request(req: Request, ctx: Context) {
  use req <- web.middleware(req)

  case req.method, wisp.path_segments(req) {
    http.Get, ["tasks"] -> handle_get_all_tasks(req, ctx)
    http.Post, ["tasks"] -> handle_insert_task(req, ctx)
    http.Post, ["tasks", id] -> handle_update_task(req, ctx, id)
    http.Delete, ["tasks", id] -> handle_delete_task(req, ctx, id)
    _, _ -> wisp.not_found()
  }
}

fn handle_get_all_tasks(_req: Request, ctx: Context) -> Response {
  let assert Ok(tasks) = task_db.get_all_tasks(ctx.db)
  tasks
  |> task.task_list_to_json()
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn handle_insert_task(req: Request, ctx: Context) -> Response {
  use description <- web.require_decoded_json(req, {
    use description <- decode.field("description", decode.string)
    decode.success(description)
  })

  let assert Ok(task) = task_db.insert_task(description, ctx.db)
  task
  |> task.task_to_json()
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn handle_update_task(req: Request, ctx: Context, id: String) -> Response {
  use task <- web.require_decoded_json(req, task.task_decoder())
  case id == task.id {
    False ->
      wisp.html_response(
        "ID didn't match URL" |> string_tree.from_string(),
        400,
      )
    True -> {
      let assert Ok(task) = task_db.update_task(task, ctx.db)
      task
      |> task.task_to_json()
      |> json.to_string_tree()
      |> wisp.json_response(200)
    }
  }
}

fn handle_delete_task(_req: Request, ctx: Context, id: String) -> Response {
  use id <- web.require_decoded_param(id, uuid.from_string)

  let assert Ok(deleted) = task_db.delete_task(id, ctx.db)
  case deleted {
    True -> wisp.html_response("Ok" |> string_tree.from_string(), 200)
    False -> wisp.not_found()
  }
}
