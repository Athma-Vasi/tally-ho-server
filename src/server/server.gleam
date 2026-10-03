import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/io
import gleam/string
import mist
import server/constants
import server/librarian
import server/sup
import server/web
import wisp
import wisp/wisp_mist

fn handle_request_hof(
  librarian_pool_subject: process.Subject(librarian.LibrarianPoolMessage),
) -> fn(request.Request(wisp.Connection)) -> response.Response(wisp.Body) {
  fn(request: request.Request(wisp.Connection)) -> response.Response(wisp.Body) {
    use request <- web.middleware(request)

    librarian.receive_call_slip(request, librarian_pool_subject)

    io.println("\n")
    io.println("Handled request: " <> string.inspect(request))

    wisp.ok()
    |> wisp.string_body("Hello there!!")
  }
}

pub fn start() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)
  // create librarian sup closure and pass 

  let librarian_pool_name = constants.librarian_pool_name |> process.new_name
  let librarian_pool_subject = process.named_subject(librarian_pool_name)
  let librarian_pool_supervisor =
    sup.start_librarian_pool_supervisor(librarian_pool_name)

  io.println("\n")
  io.println(
    "Started librarian pool supervisor for: "
    <> string.inspect(librarian_pool_name),
  )
  io.println(
    "Librarian pool supervisor: " <> string.inspect(librarian_pool_supervisor),
  )
  // process.sleep(1000)

  let request_handler = handle_request_hof(librarian_pool_subject)

  let assert Ok(_server_actor) =
    wisp_mist.handler(request_handler, secret_key_base)
    |> mist.new
    |> mist.port(5407)
    |> mist.start

  process.sleep_forever()
}
