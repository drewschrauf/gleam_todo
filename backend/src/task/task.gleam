import gleam/list
import gleam/result
import pog
import shared/task.{type Task, Task}
import task/sql
import youid/uuid.{type Uuid}

pub fn get_all_tasks(db: pog.Connection) -> Result(List(Task), String) {
  use returned <- result.try(
    sql.get_all_tasks(db)
    |> result.replace_error("Couldn't retrieve tasks from DB"),
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
  Ok(Task(
    id: row.id |> uuid.to_string(),
    description: row.description,
    done: row.done,
  ))
}

pub fn update_task(task: Task, db: pog.Connection) -> Result(Task, String) {
  use id <- result.try(
    task.id
    |> uuid.from_string()
    |> result.replace_error("Couldn't parse ID as uuid"),
  )
  use returned <- result.try(
    sql.update_task(db, id, task.description, task.done)
    |> result.replace_error("Couldn't update task in DB"),
  )

  use row <- result.try(
    returned.rows
    |> list.first()
    |> result.replace_error("Update didn't return an inserted record"),
  )
  Ok(Task(
    id: row.id |> uuid.to_string(),
    description: row.description,
    done: row.done,
  ))
}

pub fn delete_task(id: Uuid, db: pog.Connection) -> Result(Bool, String) {
  use returned <- result.try(
    sql.delete_task(db, id)
    |> result.replace_error("Couldn't delete task from DB"),
  )
  Ok(returned.count == 1)
}
