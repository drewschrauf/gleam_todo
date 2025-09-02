import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/string_tree
import shared/task
import task/task as task_db
import types/errors
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
  use tasks <- web.handle_error(task_db.get_all_tasks(ctx.db), fn(_) {
    wisp.internal_server_error()
  })

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

  use task <- web.handle_error(task_db.insert_task(description, ctx.db), fn(_) {
    wisp.internal_server_error()
  })

  task
  |> task.task_to_json()
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn handle_update_task(req: Request, ctx: Context, id: String) -> Response {
  use task <- web.require_decoded_json(req, task.task_decoder())

  use <- bool.lazy_guard(id == task.id, otherwise: fn() {
    wisp.html_response("ID didn't match URL" |> string_tree.from_string(), 400)
  })

  use task <- web.handle_error(task_db.update_task(task, ctx.db), fn(error) {
    case error {
      errors.DBNotFoundError -> wisp.not_found()
      _ -> wisp.internal_server_error()
    }
  })

  task
  |> task.task_to_json()
  |> json.to_string_tree()
  |> wisp.json_response(200)
}

fn handle_delete_task(_req: Request, ctx: Context, id: String) -> Response {
  use id <- web.require_decoded_param(id, uuid.from_string)

  use _ <- web.handle_error(task_db.delete_task(id, ctx.db), fn(error) {
    case error {
      errors.DBNotFoundError -> wisp.not_found()
      _ -> wisp.internal_server_error()
    }
  })

  wisp.html_response("Ok" |> string_tree.from_string(), 200)
}
