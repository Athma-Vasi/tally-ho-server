import gleam/dynamic/decode
import gleam/io
import server/server
import sqlight

pub fn main() -> Nil {
  server.start()
}
