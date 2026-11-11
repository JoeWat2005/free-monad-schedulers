# Free monad schedulers in Haskell

Haskell code that uses the free monad to represent computations as data, then interprets them in different ways: as rose trees, as a trace of every intermediate state, and as cooperative threads run by a scheduler.

## Context

My solution to Assignment 3 of a university functional programming module. `Assignment3.hs` is my work. The module supplied `Types.hs`, `presubmit.sh` and the brief in `DETAILS.md`.

## Features

- Convert between `Free [] a` and rose trees in both directions (`toRose`, `fromRose`)
- Run a `Free (State s)` computation while logging the state after every step (`trace`)
- Round-robin scheduler for threads that hand over control with `yield` (`roundRobin`)
- Scheduler for threads that can also sleep for a number of steps (`schedule`)
- A small demo of three yielding threads (`charWriter`, `yieldExample`)

## Tech stack

- Haskell, built with GHC
- Safe Haskell (`{-# LANGUAGE Safe #-}`), with warnings for incomplete pattern matches
- `Control.Monad.State` from the mtl package, plus `Data.Functor.Identity` and `Data.List`
- No Cabal or Stack project file

## Building and running

You need GHC with the mtl package available. The repository doesn't pin a GHC version.

The supplied check script compiles the solution, compiles it again with Safe Haskell, and confirms the exported functions still have the required type signatures:

```sh
sh presubmit.sh Assignment3
```

To try the functions, load the module into GHCi. `fibF`, `sleepExample` and the other example computations come from `Types.hs`.

```sh
ghci Assignment3.hs
```

```haskell
ghci> execState (trace (fibF 3)) ([], (0, 1))
([(2,3),(1,2),(1,2),(1,1),(1,1),(0,1)],(2,3))
ghci> execState (roundRobin yieldExample) ""   -- the string built by three interleaved threads
ghci> execState (schedule sleepExample) ""     -- the string built by three threads that sleep
```

The trace log lists the newest state first and has one entry per step, so each `get` and each `put` adds an entry.

There are no automated tests in the repository.

## How it works

`Types.hs` defines `Free`, with its `Functor`, `Applicative` and `Monad` instances, along with `liftF`, the `Rose` type, the functor sum `FSum`, the `Yield` and `Sleep` functors, and example computations. `Assignment3.hs` contains the interpreters.

- **Rose trees.** `toRose` maps `Pure x` to a leaf (`Lf x`) and `Free xs` to a branch (`Br`) of converted children. `fromRose` does the reverse, so the two functions are inverses.
- **Tracing.** `trace` interprets a `Free (State s)` computation in the `State ([s], s)` monad. For each `Free` layer it runs one step of the underlying state action with `runState`, adds the new state to the front of the log, and carries on with the rest of the computation.
- **Round-robin scheduling.** A thread has type `YieldState s ()`, a free monad over `FSum (State s) Yield`. `step` runs a thread's state actions until it reaches a `yield`, returning the continuation, or finishes, returning `Nothing`. `roundRobin` runs the thread at the front of the list, drops it if it finished, and otherwise moves its continuation to the back.
- **Sleeping threads.** `schedule` pairs each `SleepState s ()` thread with a sleep counter that starts at 0, then repeatedly runs the first thread whose counter is 0. `runThread` executes that thread until it sleeps or finishes, decrementing the other threads' counters (never below 0, using `decCounter`) after every state step. A thread that goes to sleep returns to its place in the list with its new counter, and a finished thread is removed. When every thread is asleep, all counters go down by one and the scheduler tries again.

## Notes

`Types.hs` uses `deriving instance` and `deriving Functor` without switching on the matching language extensions, so a GHC that defaults to Haskell 2010 will reject it.

## Project structure

```text
free-monad-schedulers/
├── Assignment3.hs   # my solutions: toRose, fromRose, trace, roundRobin, schedule
├── Types.hs         # Free monad, Rose, FSum, Yield and Sleep types and examples (supplied)
├── presubmit.sh     # compile and type-signature check (supplied)
├── DETAILS.md       # the assignment brief (supplied)
├── LICENSE
└── README.md
```

## Licence

See [LICENSE](LICENSE).
