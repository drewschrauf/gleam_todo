import envoy
import gleam/erlang/process
import gleam/otp/static_supervisor
import mist
import pog
import router
import web
import wisp
import wisp/wisp_mist

fn get_db() {
  let name = process.new_name("database")

  let assert Ok(database_url) = envoy.get("DATABASE_URL")
  let assert Ok(config) = pog.url_config(name, database_url)

  let spec = config |> pog.supervised()
  let connection = pog.named_connection(name)

  #(spec, connection)
}

fn get_app(ctx: web.Context) {
  wisp.configure_logger()
  let secret_key_base = "iamverysecret"

  wisp_mist.handler(router.handle_request(_, ctx), secret_key_base)
  |> mist.new()
  |> mist.port(4444)
  |> mist.supervised()
}

pub fn main() {
  let #(db, connection) = get_db()
  let ctx = web.Context(db: connection)
  let app = get_app(ctx)

  let assert Ok(_) =
    static_supervisor.new(static_supervisor.RestForOne)
    |> static_supervisor.add(db)
    |> static_supervisor.add(app)
    |> static_supervisor.start()

  process.sleep_forever()
}
