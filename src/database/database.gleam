import gleam/dynamic/decode
import gleam/io
import sqlight

pub fn connect() -> Nil {
  let _conn_result =
    sqlight.with_connection(
      "file:./src/sqlite_db/testing.sqlite3",
      fn(connection) {
        let sql =
          "
  create table cats (name text, age int);

  insert into cats (name, age) values 
  ('Nubi', 4),
  ('Biffy', 10),
  ('Ginny', 6);
  "
        let assert Ok(Nil) = sqlight.exec(sql, connection)

        let cat_decoder = {
          use name <- decode.field(0, decode.string)
          use age <- decode.field(1, decode.int)
          decode.success(#(name, age))
        }

        let sql =
          "
  select name, age from cats
  where age < ?
  "
        let assert Ok([#("Nubi", 4), #("Ginny", 6)]) =
          sqlight.query(
            sql,
            on: connection,
            with: [sqlight.int(7)],
            expecting: cat_decoder,
          )

        io.println("Query executed successfully")
      },
    )
}
