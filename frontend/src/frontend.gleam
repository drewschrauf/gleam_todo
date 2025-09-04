import frontend/api
import gleam/dynamic/decode
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/element/keyed
import lustre/event
import lustre_http
import remote_data.{type RemoteData, Failure, Loading, NotRequested, Success}
import shared/task.{type Task}
import sketch/css
import sketch/lustre as sketch_lustre
import sketch/lustre/element.{class_name} as _

pub fn main() -> Nil {
  let assert Ok(stylesheet) = sketch_lustre.setup()
  let app = lustre.application(init, update, view(_, stylesheet))
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type NewTask {
  NewTask(description: String, submitting: Bool)
}

type Model {
  Model(tasks: RemoteData(List(Task), lustre_http.HttpError), new_task: NewTask)
}

type Msg {
  ServerRespondedToTaskListRequest(Result(List(Task), lustre_http.HttpError))
  UserUpdatedNewTaskDescription(String)
  UserSubmittedNewTaskForm
  UserClickedDelete(String)
  ServerRespondedToTaskDeletionRequest(
    String,
    Result(Nil, lustre_http.HttpError),
  )
  ServerRespondedToNewTaskSubmissionRequest(Result(Task, lustre_http.HttpError))
}

fn init(_flags) {
  #(
    Model(tasks: Loading, new_task: NewTask(description: "", submitting: False)),
    api.get_all_tasks(ServerRespondedToTaskListRequest),
  )
}

fn update(model, msg) {
  case msg {
    ServerRespondedToTaskListRequest(response) ->
      case response {
        Ok(tasks) -> #(Model(..model, tasks: Success(tasks)), effect.none())
        Error(error) -> #(Model(..model, tasks: Failure(error)), effect.none())
      }

    UserUpdatedNewTaskDescription(description) -> #(
      Model(..model, new_task: NewTask(..model.new_task, description:)),
      effect.none(),
    )
    UserSubmittedNewTaskForm -> {
      case model.new_task.description {
        "" -> #(model, effect.none())
        description -> #(
          Model(..model, new_task: NewTask(..model.new_task, submitting: True)),
          api.add_task(description, ServerRespondedToNewTaskSubmissionRequest),
        )
      }
    }
    ServerRespondedToNewTaskSubmissionRequest(response) -> {
      case response {
        Ok(task) -> #(
          Model(
            tasks: model.tasks |> remote_data.map(list.append(_, [task])),
            new_task: NewTask(description: "", submitting: False),
          ),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    }

    UserClickedDelete(id) -> {
      #(model, api.delete_task(id, ServerRespondedToTaskDeletionRequest(id, _)))
    }
    ServerRespondedToTaskDeletionRequest(id, response) -> {
      case response {
        Ok(_) -> #(
          Model(
            ..model,
            tasks: model.tasks
              |> remote_data.map(fn(tasks) {
                tasks |> list.filter(fn(task) { task.id != id })
              }),
          ),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    }
  }
}

fn on_specific_keydown(target_key: String, msg: msg) -> attribute.Attribute(msg) {
  event.on("keydown", {
    use _ <- decode.field(
      "key",
      decode.string
        |> decode.then(fn(key) {
          case key {
            key if key == target_key -> decode.success(Nil)
            _ -> decode.failure(Nil, "Key wasn't Enter")
          }
        }),
    )
    decode.success(msg)
  })
}

fn app_class() {
  css.class([css.font_family("sans-serif")])
}

fn title_class() {
  css.class([
    css.color("red"),
  ])
}

fn task_class(done: Bool) {
  css.class(
    []
    |> list.append(case done {
      True -> [css.text_decoration("line-through")]
      False -> []
    }),
  )
}

fn view(model: Model, stylesheet) {
  use <- sketch_lustre.render(stylesheet:, in: [sketch_lustre.node()])

  html.div([attribute.class(app_class() |> class_name())], [
    html.h1(
      [
        attribute.class(title_class() |> class_name()),
      ],
      [element.text("Tasks!")],
    ),
    case model.tasks {
      NotRequested | Loading -> element.text("Loading...")
      Failure(_) -> element.text("Something went wrong")
      Success(tasks) ->
        element.fragment([
          case tasks {
            [] -> html.p([], [element.text("No tasks!")])
            _ as tasks ->
              keyed.ul(
                [],
                tasks
                  |> list.map(fn(task) {
                    #(
                      task.id,
                      html.li(
                        [attribute.class(task_class(task.done) |> class_name())],
                        [
                          element.text(task.description),
                          html.button(
                            [event.on_click(UserClickedDelete(task.id))],
                            [
                              element.text("x"),
                            ],
                          ),
                        ],
                      ),
                    )
                  }),
              )
          },
          html.label([attribute.for("new-task-description")], [
            element.text("New task"),
          ]),
          html.input([
            attribute.id("new-task-description"),
            attribute.autofocus(!model.new_task.submitting),
            attribute.disabled(model.new_task.submitting),
            attribute.value(model.new_task.description),
            event.on_input(UserUpdatedNewTaskDescription),
            on_specific_keydown("Enter", UserSubmittedNewTaskForm),
          ]),
          html.button(
            [
              event.on_click(UserSubmittedNewTaskForm),
              attribute.disabled(model.new_task.submitting),
            ],
            [element.text("Submit")],
          ),
        ])
    },
  ])
}
