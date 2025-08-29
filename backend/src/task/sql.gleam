//// This module contains the code to run the sql queries defined in
//// `./src/task/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import pog
import youid/uuid.{type Uuid}

/// A row you get from running the `delete_task` query
/// defined in `./src/task/sql/delete_task.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteTaskRow {
  DeleteTaskRow(id: Uuid, description: String, done: Bool)
}

/// Runs the `delete_task` query
/// defined in `./src/task/sql/delete_task.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_task(
  db: pog.Connection,
  arg_1: Uuid,
) -> Result(pog.Returned(DeleteTaskRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.string)
    use done <- decode.field(2, decode.bool)
    decode.success(DeleteTaskRow(id:, description:, done:))
  }

  "DELETE FROM tasks WHERE tasks.id = $1 RETURNING *
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_all_tasks` query
/// defined in `./src/task/sql/get_all_tasks.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetAllTasksRow {
  GetAllTasksRow(id: Uuid, description: String, done: Bool)
}

/// Runs the `get_all_tasks` query
/// defined in `./src/task/sql/get_all_tasks.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_all_tasks(
  db: pog.Connection,
) -> Result(pog.Returned(GetAllTasksRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.string)
    use done <- decode.field(2, decode.bool)
    decode.success(GetAllTasksRow(id:, description:, done:))
  }

  "SELECT * FROM tasks
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `insert_task` query
/// defined in `./src/task/sql/insert_task.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type InsertTaskRow {
  InsertTaskRow(id: Uuid, description: String, done: Bool)
}

/// Runs the `insert_task` query
/// defined in `./src/task/sql/insert_task.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn insert_task(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(InsertTaskRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.string)
    use done <- decode.field(2, decode.bool)
    decode.success(InsertTaskRow(id:, description:, done:))
  }

  "INSERT INTO tasks (description) VALUES ($1) RETURNING *
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_task` query
/// defined in `./src/task/sql/update_task.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateTaskRow {
  UpdateTaskRow(id: Uuid, description: String, done: Bool)
}

/// Runs the `update_task` query
/// defined in `./src/task/sql/update_task.sql`.
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_task(
  db: pog.Connection,
  arg_1: Uuid,
  arg_2: String,
  arg_3: Bool,
) -> Result(pog.Returned(UpdateTaskRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, uuid_decoder())
    use description <- decode.field(1, decode.string)
    use done <- decode.field(2, decode.bool)
    decode.success(UpdateTaskRow(id:, description:, done:))
  }

  "UPDATE tasks SET description = $2, done = $3 WHERE id = $1 RETURNING *
"
  |> pog.query
  |> pog.parameter(pog.text(uuid.to_string(arg_1)))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.bool(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Encoding/decoding utils -------------------------------------------------

/// A decoder to decode `Uuid`s coming from a Postgres query.
///
fn uuid_decoder() {
  use bit_array <- decode.then(decode.bit_array)
  case uuid.from_bit_array(bit_array) {
    Ok(uuid) -> decode.success(uuid)
    Error(_) -> decode.failure(uuid.v7(), "Uuid")
  }
}
