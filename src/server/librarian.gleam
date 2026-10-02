import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/otp/actor

pub opaque type LibrarianPoolMessage

type LibrarianPoolSubject =
  process.Subject(LibrarianPoolMessage)

type CallSlip =
  #(String)

type CallSlipsQueue =
  List(CallSlip)

type LibrarianPoolState =
  #(CallSlipsQueue, LibrariansRoster)

type LibrariansRoster =
  dict.Dict(process.Name(LibrarianMessage), LibrarianState)

pub opaque type LibrarianMessage

type LibrarianSubject =
  process.Subject(LibrarianMessage)

type LibrarianStatus {
  Available
  Busy
  Offline
}

type LibrarianRestarts =
  Int

type LibrarianState =
  #(LibrarianStatus, LibrarianRestarts)

fn handle_pool_message(
  state: LibrarianPoolState,
  message: LibrarianPoolMessage,
) {
  actor.continue(state)
}

pub fn new_pool(
  name: process.Name(LibrarianPoolMessage),
  librarian_names: List(process.Name(LibrarianMessage)),
) {
  let call_slips_queue: CallSlipsQueue = []
  let initial_librarians_roster: LibrariansRoster = dict.new()
  let librarians_roster =
    librarian_names
    |> list.fold(
      from: initial_librarians_roster,
      with: fn(roster, librarian_name) {
        let status = Available
        let restarts = 0
        let librarian_state: LibrarianState = #(status, restarts)

        roster |> dict.insert(librarian_name, librarian_state)
      },
    )
  let state = #(call_slips_queue, librarians_roster)

  actor.new(state)
  |> actor.named(name)
  |> actor.on_message(handle_pool_message)
  |> actor.start()
}

fn handle_librarian_message(state: List(Nil), message: LibrarianMessage) {
  actor.continue(state)
}

pub fn new_librarian(name: process.Name(LibrarianMessage)) {
  actor.new([])
  |> actor.named(name)
  |> actor.on_message(handle_librarian_message)
  |> actor.start()
}
