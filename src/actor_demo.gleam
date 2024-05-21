//// A demonstration/reminder of how Actors are set up in Gleam.

import gleam/io
import gleam/otp/actor
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}

pub fn main() {
  io.println("START")
  let assert Ok(logger) = actor.start(Nil, handle_logger_message)

  io.println("Starting a logging actor")
  let initial_name_tally_state =
    TallyState(label: "Names", tally: dict.new(), logger: logger)

  io.println("Starting a tallying actor")
  let assert Ok(name_tally) =
    actor.start(initial_name_tally_state, handle_name_message)

  io.println("Sending a bunch of talliable messages.")
  [
    Introduce("Joe"),
    Introduce("Alice"),
    Introduce("Joe"),
    Introduce("Benny"),
    Summarize,
  ]
  |> list.each(fn(msg) { process.send(name_tally, msg) })

  io.println("Sleeping")
  process.sleep(3)

  io.println("Shutting down")
  process.send(name_tally, Shutdown)
  io.println("END")
}

pub type TallyState {
  TallyState(
    label: String,
    tally: Dict(String, Int),
    logger: Subject(Option(String)),
  )
}

pub type TallyMessage {
  Introduce(String)
  Summarize
  Shutdown
}

/// Counts the people it's been introduced to, and the number of times they've
/// been met.
pub fn handle_name_message(
  message: TallyMessage,
  state: TallyState,
) -> actor.Next(TallyMessage, TallyState) {
  case message {
    Introduce(name) -> {
      let new_state =
        TallyState(
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

/// A very simple, stateless handler. Either gets a `String`, which it logs, or `None`,
/// meaning shutdown.
pub fn handle_logger_message(
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
