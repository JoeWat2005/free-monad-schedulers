# Free Monad Schedulers in Haskell

This repository contains my solution to **Assignment 3**, which explores the **Free monad** in Haskell and its use for representing, tracing, and scheduling effectful computations.

## Overview

The assignment focuses on using the `Free` monad to turn monadic computations into data, allowing them to be interpreted in different ways. The implemented tasks include:

- Viewing **rose trees** as `Free []`
- Tracing stateful computations using `Free (State s)`
- Implementing a **round-robin scheduler** using explicit `yield`
- Extending the scheduler to support **sleeping threads**

All solutions follow the provided assignment template and required type signatures.

## Repository Structure

- `Assignment3.hs`  
  Main solution file containing all implemented tasks.

- `Types.hs`  
  Preset Haskell data types and definitions provided for the assignment.

- `DETAILS.md`  
  The original assignment specification describing the exercises that were completed.

- `presubmit.sh`  
  Script used to check compilation and submission readiness.

- `.gitignore`  
  Standard Git ignore rules for Haskell build artifacts.

## Notes

This repository is intended for **educational purposes** and reflects coursework completed as part of a university functional programming module.

---


