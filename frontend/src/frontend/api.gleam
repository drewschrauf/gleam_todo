import gleam/http
import gleam/http/request
import gleam/json
import lustre/effect
import lustre_http
import shared/task.{type Task}

pub fn get_all_tasks(
  on_result: fn(Result(List(Task), lustre_http.HttpError)) -> msg,
) -> effect.Effect(msg) {
  lustre_http.get(
    "http://localhost:4444/tasks",
    lustre_http.expect_json(task.task_list_decoder(), on_result),
  )
}

pub fn add_task(
  description: String,
  on_result: fn(Result(Task, lustre_http.HttpError)) -> msg,
) -> effect.Effect(msg) {
  lustre_http.post(
    "http://localhost:4444/tasks",
    json.object([#("description", description |> json.string())]),
    lustre_http.expect_json(task.task_decoder(), on_result),
  )
}

pub fn delete_task(
  id: String,
  on_result: fn(Result(Nil, lustre_http.HttpError)) -> msg,
) -> effect.Effect(msg) {
  lustre_http.send(
    {
      let assert Ok(request) = request.to("http://localhost:4444/tasks/" <> id)
      request
      |> request.set_method(http.Delete)
    },
    lustre_http.expect_anything(on_result),
  )
}
