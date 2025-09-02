import gleam/list
import gleam/result
import pog
import shared/task.{type Task, Task}
import task/sql
import types/errors.{
  type DBError, DBNotFoundError, DBQueryError, DBValidationError,
}
import youid/uuid.{type Uuid}

pub fn get_all_tasks(db: pog.Connection) -> Result(List(Task), DBError) {
  use returned <- result.try(
    sql.get_all_tasks(db)
    |> result.map_error(DBQueryError),
  )

  returned.rows
  |> list.map(fn(row) {
    Task(
      id: row.id |> uuid.to_string(),
      description: row.description,
      done: row.done,
    )
  })
  |> Ok()
}

pub fn insert_task(
  description: String,
  db: pog.Connection,
) -> Result(Task, DBError) {
  use returned <- result.try(
    sql.insert_task(db, description)
    |> result.map_error(DBQueryError),
  )
  use row <- result.try(
    returned.rows
    |> list.first()
    |> result.replace_error(DBNotFoundError),
  )
  Ok(Task(
    id: row.id |> uuid.to_string(),
    description: row.description,
    done: row.done,
  ))
}

pub fn update_task(task: Task, db: pog.Connection) -> Result(Task, DBError) {
  use id <- result.try(
    task.id
    |> uuid.from_string()
    |> result.replace_error(DBValidationError("Couldn't parse ID as uuid")),
  )
  use returned <- result.try(
    sql.update_task(db, id, task.description, task.done)
    |> result.map_error(DBQueryError),
  )

  use row <- result.try(
    returned.rows
    |> list.first()
    |> result.replace_error(DBNotFoundError),
  )

  Ok(Task(
    id: row.id |> uuid.to_string(),
    description: row.description,
    done: row.done,
  ))
}

pub fn delete_task(id: Uuid, db: pog.Connection) -> Result(Nil, DBError) {
  use returned <- result.try(
    sql.delete_task(db, id)
    |> result.map_error(DBQueryError),
  )

  case returned.count == 1 {
    True -> Ok(Nil)
    False -> Error(DBNotFoundError)
  }
}
