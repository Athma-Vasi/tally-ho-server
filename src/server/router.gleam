import server/web
import wisp

pub fn handle_request(request: wisp.Request) -> wisp.Response {
  use _request <- web.middleware(request)

  let body = "<html><body><h1>Hello, World!</h1></body></html>"

  wisp.html_response(body, 200)
}
