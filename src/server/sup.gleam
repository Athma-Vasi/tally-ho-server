import gleam/erlang/process
import gleam/list
import gleam/otp/static_supervisor
import gleam/otp/supervision
import server/librarian
import wisp

fn generate_librarian_uuid() {
  wisp.random_string(64) <> wisp.random_string(64) <> wisp.random_string(64)
}

fn generate_librarian_names(
  n: Int,
) -> List(process.Name(librarian.LibrarianMessage)) {
  generate_librarian_uuid() |> process.new_name |> list.repeat(times: n)
}

const librarians_limit = 10

fn generate_librarian_subjects(
  librarians_names: List(process.Name(librarian.LibrarianMessage)),
) -> List(process.Subject(librarian.LibrarianMessage)) {
  librarians_names
  |> list.map(fn(name) { process.named_subject(name) })
}

fn start_librarian_pool(
  librarian_pool_name: process.Name(librarian.LibrarianPoolMessage),
  librarian_names: List(process.Name(librarian.LibrarianMessage)),
) {
  fn() {
    librarian.new_pool(
      librarian_pool_name,
      generate_librarian_subjects(librarian_names),
    )
  }
}

fn start_librarian(
  librarian_name: process.Name(librarian.LibrarianMessage),
  librarian_pool_name: process.Name(librarian.LibrarianPoolMessage),
) {
  fn() {
    let librarian_subject = process.named_subject(librarian_name)
    let librarian_pool_subject = process.named_subject(librarian_pool_name)
    let new_librarian = librarian.new_librarian(librarian_name)

    // librarian.librarian_restart(librarian_subject, librarian_pool_subject)

    new_librarian
  }
}

fn start_librarians(
  librarian_sup_builder: static_supervisor.Builder,
  librarian_pool_name: process.Name(librarian.LibrarianPoolMessage),
  librarian_names: List(process.Name(librarian.LibrarianMessage)),
) -> static_supervisor.Builder {
  librarian_names
  |> list.fold(
    from: librarian_sup_builder,
    with: fn(sup_builder, librarian_name) {
      sup_builder
      |> static_supervisor.add(
        supervision.worker(start_librarian(librarian_name, librarian_pool_name)),
      )
    },
  )
}

pub fn start_librarian_pool_supervisor(
  librarian_pool_name: process.Name(librarian.LibrarianPoolMessage),
) -> supervision.ChildSpecification(static_supervisor.Supervisor) {
  let librarian_names = generate_librarian_names(librarians_limit)

  let librarian_sup_builder =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(
      supervision.worker(start_librarian_pool(
        librarian_pool_name,
        librarian_names,
      )),
    )

  start_librarians(librarian_sup_builder, librarian_pool_name, librarian_names)
  |> static_supervisor.restart_tolerance(intensity: 10, period: 1000)
  |> static_supervisor.supervised
}
