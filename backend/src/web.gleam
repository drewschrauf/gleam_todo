import envoy
import gleam/dynamic/decode
import gleam/http
import gleam/http/response
import gleam/json
import gleam/string
import gleam/string_tree
import pog
import wisp.{type Request, type Response}

pub type Context {
  Context(db: pog.Connection)
}

fn logger(req: Request, next: fn() -> Response) {
  case envoy.get("ENVIRONMENT") {
    Ok("test") -> next()
    _ -> wisp.log_request(req, next)
  }
}

fn cors(req: Request, next: fn() -> Response) {
  let add_cors_headers = fn(req) {
    req
    |> response.set_header("Access-Control-Allow-Origin", "*")
    |> response.set_header("Access-Control-Allow-Methods", "*")
    |> response.set_header("Access-Control-Allow-Headers", "*")
  }
  case req.method {
    http.Options ->
      wisp.html_response("" |> string_tree.from_string(), 200)
      |> add_cors_headers()
    _ ->
      next()
      |> add_cors_headers()
  }
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- logger(req)
  use <- wisp.rescue_crashes()
  use <- cors(req)
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn require_decoded_json(
  req: Request,
  decoder: decode.Decoder(a),
  next: fn(a) -> Response,
) -> Response {
  use json <- wisp.require_json(req)
  case decode.run(json, decoder) {
    Ok(data) -> next(data)
    Error(errors) -> {
      json.array(errors, fn(error) {
        json.object([
          #("expected", json.string(error.expected)),
          #("found", json.string(error.found)),
          #("path", json.string(error.path |> string.join("."))),
        ])
      })
      |> json.to_string_tree()
      |> wisp.json_response(400)
    }
  }
}

/// Converts a parameter using the provided decoder. If the decoder fails, returns a 404.
pub fn require_decoded_param(
  param: a,
  decoder: fn(a) -> Result(b, c),
  next: fn(b) -> Response,
) -> Response {
  case decoder(param) {
    Ok(decoded) -> next(decoded)
    Error(_) -> wisp.not_found()
  }
}

pub fn handle_error(
  result: Result(data, error),
  on_error: fn(error) -> result,
  on_ok: fn(data) -> result,
) -> result {
  case result {
    Ok(data) -> on_ok(data)
    Error(error) -> on_error(error)
  }
}
