import gleam/json
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http
import remote_data.{type RemoteData, Failure, Loading, NotRequested, Success}
import shared/task.{type Task}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    tasks: RemoteData(List(Task), lustre_http.HttpError),
    new_task_description: String,
    submitting: Bool,
  )
}

type Msg {
  GotTasks(Result(List(Task), lustre_http.HttpError))
  UserUpdatedNewTaskDescription(String)
  UserClickedSubmit
  NewTaskSubmitted(Result(Task, lustre_http.HttpError))
}

fn init(_flags) {
  #(
    Model(tasks: Loading, new_task_description: "", submitting: False),
    lustre_http.get(
      "http://localhost:4444/tasks",
      lustre_http.expect_json(task.task_list_decoder(), GotTasks),
    ),
  )
}

fn update(model, msg) {
  case msg {
    GotTasks(response) ->
      case response {
        Ok(tasks) -> #(Model(..model, tasks: Success(tasks)), effect.none())
        Error(error) -> #(Model(..model, tasks: Failure(error)), effect.none())
      }
    UserUpdatedNewTaskDescription(new_task_description) -> #(
      Model(..model, new_task_description:),
      effect.none(),
    )
    UserClickedSubmit -> {
      case model.new_task_description {
        "" -> #(model, effect.none())
        description -> #(
          Model(..model, submitting: True),
          lustre_http.post(
            "http://localhost:4444/tasks",
            json.object([#("description", description |> json.string())]),
            lustre_http.expect_json(task.task_decoder(), NewTaskSubmitted),
          ),
        )
      }
    }
    NewTaskSubmitted(response) -> {
      case response {
        Ok(task) -> #(
          Model(
            tasks: model.tasks |> remote_data.map(list.append(_, [task])),
            new_task_description: "",
            submitting: False,
          ),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    }
  }
}

fn view(model: Model) {
  html.div([], [
    html.h1([], [element.text("Tasks!")]),
    case model.tasks {
      NotRequested | Loading -> element.text("Loading...")
      Failure(_) -> element.text("Something went wrong")
      Success(tasks) ->
        html.div([], [
          html.ul(
            [],
            tasks
              |> list.map(fn(task) {
                html.li([], [
                  element.text(task.description),
                  html.button([], [element.text("x")]),
                ])
              }),
          ),
          html.label([], [
            element.text("New task"),
            html.input([
              attribute.disabled(model.submitting),
              attribute.value(model.new_task_description),
              event.on_input(UserUpdatedNewTaskDescription),
            ]),
          ]),
          html.button(
            [
              event.on_click(UserClickedSubmit),
              attribute.disabled(model.submitting),
            ],
            [element.text("Submit")],
          ),
        ])
    },
  ])
}
