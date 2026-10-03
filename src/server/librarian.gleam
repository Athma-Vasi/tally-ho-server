import gleam/dict
import gleam/erlang/process
import gleam/http/request
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/string
import wisp

pub opaque type LibrarianPoolMessage {
  ReceiveCallSlip(
    call_slip: CallSlip,
    librarian_pool_subject: LibrarianPoolSubject,
  )

  LibrarianSuccess(
    librarian_subject: LibrarianSubject,
    librarian_pool_subject: LibrarianPoolSubject,
  )

  LibrarianFailure(
    librarian_subject: LibrarianSubject,
    librarian_pool_subject: LibrarianPoolSubject,
  )

  LibrarianRestart(
    librarian_subject: LibrarianSubject,
    librarian_pool_subject: LibrarianPoolSubject,
  )
  //   LibrarianOffline(
  //     librarian_subject: LibrarianSubject,
  //     librarian_pool_subject: LibrarianPoolSubject,
  //   )
}

type LibrarianPoolSubject =
  process.Subject(LibrarianPoolMessage)

type CallSlip =
  request.Request(wisp.Connection)

type CallSlipsQueue =
  List(CallSlip)

type AvailableLibrarians =
  List(LibrarianSubject)

type LibrarianPoolState =
  #(CallSlipsQueue, AvailableLibrarians, LibrariansRoster)

type LibrariansRoster =
  dict.Dict(LibrarianSubject, LibrarianState)

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
  let #(call_slips_queue, available_librarians, librarians_roster) = state

  case message {
    ReceiveCallSlip(call_slip, librarian_pool_subject) -> {
      io.println("\n")
      io.println("Received call slip: " <> string.inspect(call_slip))

      // insert into queue
      let updated_call_slips_queue =
        call_slips_queue |> list.append([call_slip])

      case available_librarians {
        // if all busy, continue after adding to queue
        [] ->
          actor.continue(#(
            updated_call_slips_queue,
            available_librarians,
            librarians_roster,
          ))

        [available_librarian, ..rest_available_librarians] -> {
          give_call_slip_to_librarian(
            call_slip,
            available_librarian,
            librarian_pool_subject,
          )

          actor.continue(#(
            updated_call_slips_queue,
            rest_available_librarians,
            librarians_roster,
          ))
        }
      }

      // find available librarians
      // Handle receiving a call slip
      actor.continue(state)
    }
    LibrarianSuccess(librarian_subject, librarian_pool_subject) -> {
      // Handle librarian success
      actor.continue(state)
    }
    LibrarianFailure(librarian_subject, librarian_pool_subject) -> {
      // Handle librarian failure
      actor.continue(state)
    }
    LibrarianRestart(librarian_subject, librarian_pool_subject) -> {
      // Handle librarian restart
      actor.continue(state)
    }
  }
}

pub fn new_pool(
  name: process.Name(LibrarianPoolMessage),
  librarian_subjects: List(LibrarianSubject),
) {
  let call_slips_queue: CallSlipsQueue = []
  let initial_librarians_roster: LibrariansRoster = dict.new()
  let librarians_roster =
    librarian_subjects
    |> list.fold(
      from: initial_librarians_roster,
      with: fn(roster, librarian_subject) {
        let status = Available
        let restarts = 0
        let librarian_state: LibrarianState = #(status, restarts)

        roster |> dict.insert(librarian_subject, librarian_state)
      },
    )
  let state = #(call_slips_queue, librarian_subjects, librarians_roster)

  io.println("\n")
  io.println("Starting new librarian pool: " <> string.inspect(name))
  io.println("Initial librarians roster: " <> string.inspect(librarians_roster))
  io.println("Call slips queue: " <> string.inspect(call_slips_queue))
  io.println("Librarian pool state: " <> string.inspect(state))

  actor.new(state)
  |> actor.named(name)
  |> actor.on_message(handle_pool_message)
  |> actor.start()
}

pub fn receive_call_slip(
  call_slip: CallSlip,
  librarian_pool_subject: LibrarianPoolSubject,
) {
  io.println("\n")
  io.println("Sending call slip: " <> string.inspect(call_slip))
  io.println("To librarian pool: " <> string.inspect(librarian_pool_subject))

  actor.send(
    librarian_pool_subject,
    ReceiveCallSlip(call_slip, librarian_pool_subject),
  )
}

// ~~~~~ Librarian Actor ~~~~~

pub opaque type LibrarianMessage {
  ReceiveCallSlipFromPool(
    call_slip: CallSlip,
    librarian_subject: LibrarianSubject,
    librarian_pool_subject: LibrarianPoolSubject,
  )
}

type LibrarianSubject =
  process.Subject(LibrarianMessage)

fn handle_librarian_message(state: List(Nil), message: LibrarianMessage) {
  actor.continue(state)
}

pub fn new_librarian(name: process.Name(LibrarianMessage)) {
  io.println("\n")
  io.println("Starting new librarian actor: " <> string.inspect(name))

  actor.new([])
  |> actor.named(name)
  |> actor.on_message(handle_librarian_message)
  |> actor.start()
}

fn give_call_slip_to_librarian(
  call_slip: CallSlip,
  librarian_subject: LibrarianSubject,
  librarian_pool_subject: LibrarianPoolSubject,
) {
  librarian_subject
  |> actor.send(ReceiveCallSlipFromPool(
    call_slip,
    librarian_subject,
    librarian_pool_subject,
  ))
}
