import gleam/http
import gleam/string
import server/web
import wisp

pub fn handle_request(request: wisp.Request) -> wisp.Response {
  use _request <- web.middleware(request)

  // let body = "<html><body><h1>Hello, World!</h1></body></html>"

  // wisp.html_response(body, 200)

  case request.method, wisp.path_segments(request) {
    http.Get, ["base"] -> {
      wisp.ok() |> wisp.string_body("Hello, Reality.")
    }

    _, ["base"] -> wisp.method_not_allowed([http.Get])

    _, segment -> {
      echo "path segment: " <> string.inspect(segment)
      wisp.not_found()
    }
  }
}
