import gleam/io
import gleam/otp/actor
import gleam/option.{type Option, None, Some}
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}

pub fn main() {
  io.println("START")
  let assert Ok(logger) = actor.start(Nil, handle_logger_message)

  io.println("Starting a logging actor")
  let initial_name_tallier_state: TallierState =
    TallierState(label: "Names", tally: dict.new(), logger: logger)

  io.println("Starting a tallying actor")
  let assert Ok(name_tallier) =
    actor.start(initial_name_tallier_state, handle_name_message)

  io.println("Sending a bunch of talliable messages.")
  process.send(name_tallier, Introduce("Joe"))
  process.send(name_tallier, Introduce("Alice"))
  process.send(name_tallier, Introduce("Joe"))
  process.send(name_tallier, Introduce("Benny"))
  process.send(name_tallier, Summarize)

  io.println("Sleeping")
  process.sleep(3)

  io.println("Shutting down")
  process.send(name_tallier, Shutdown)
  io.println("END")
}

type TallierState {
  TallierState(
    label: String,
    tally: Dict(String, Int),
    logger: Subject(Option(String)),
  )
}

type Message {
  Introduce(String)
  Summarize
  Shutdown
}

fn handle_name_message(
  message: Message,
  state: TallierState,
) -> actor.Next(Message, TallierState) {
  case message {
    Introduce(name) -> {
      let new_state =
        TallierState(
          ..state,
          tally: dict.update(state.tally, name, fn(existing) {
            case existing {
              None -> 1
              Some(n) -> n + 1
            }
          }),
        )
      process.send(state.logger, Some(name))
      actor.Continue(new_state, None)
    }

    Shutdown -> {
      io.println("Stopping...")
      actor.Stop(process.Normal)
    }

    Summarize -> {
      io.debug(state)
      actor.Continue(state, None)
    }
  }
}

fn handle_logger_message(
  message: Option(String),
  state: Nil,
) -> actor.Next(Option(String), Nil) {
  case message {
    Some(txt) -> {
      io.println("Logging: " <> txt)
      actor.Continue(state, None)
    }
    None -> actor.Stop(process.Normal)
  }
}
