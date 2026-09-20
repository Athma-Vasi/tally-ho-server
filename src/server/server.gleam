import gleam/erlang/process
import mist
import server/router
import wisp
import wisp/wisp_mist

pub fn start() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(5407)
    |> mist.start

  process.sleep_forever()
}
