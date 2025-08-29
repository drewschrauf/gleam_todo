set tempdir := "."

[working-directory: 'backend']
db:
  docker run --rm --name gleam_todo -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres

[working-directory: 'backend']
dev:
  rg -l . | entr -cdr gleam run

[working-directory: 'backend']
db-migrate-new name:
  gleam run -m cigogne new --name {{name}}

[working-directory: 'backend']
db-migrate:
  gleam run -m cigogne last

[working-directory: 'backend']
regenerate-sql:
  gleam run -m squirrel


[working-directory: 'backend']
test-watch:
  #!/usr/bin/env sh
  trap 'echo "cleaning up..." && docker kill gleam_todo_tests' EXIT
  docker run -d --rm --name gleam_todo_tests -p 5555:5432 -e POSTGRES_PASSWORD=postgres postgres
  until docker exec -it gleam_todo_tests pg_isready -U postgres -d postgres -h localhost
  do
    sleep 1;
  done
  DATABASE_URL=postgres://postgres:postgres@localhost:5555/postgres gleam run -m cigogne last
  rg -l . | ENVIRONMENT=test entr -cdr gleam test
