-- setting the "warn-incomplete-patterns" flag asks GHC to warn you
-- about possible missing cases in pattern-matching definitions
{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

-- see https://wiki.haskell.org/Safe_Haskell
{-# LANGUAGE NoGeneralizedNewtypeDeriving, Safe #-}

module Assignment3 (toRose, fromRose, trace, roundRobin, schedule) where

import Types
import Control.Monad.State
import Data.Functor.Identity
import Data.List 

---------------------------------------------------------------------------------
---------------- DO **NOT** MAKE ANY CHANGES ABOVE THIS LINE --------------------
---------------------------------------------------------------------------------



{- Question 1 -}



toRose :: Free [] a -> Rose a
--convert a free structure into a rose tree.
toRose (Pure x)     = Lf x
--pure becomes a leaf node.
toRose (Free xs)    = Br (map toRose xs)
--free list becomes a branch of converted subtrees.

fromRose :: Rose a -> Free [] a
--convert a rose tree back into a free structure.
fromRose (Lf x)     = Pure x
--leaf becomes pure
fromRose (Br xs)    = Free (map fromRose xs)
--branch becomes free list of converted subtrees.



{- Question 2 -}



trace :: FreeState s a -> State ([s],s) a
--execute a state computation one step at a time recording intermediate states in log.
trace (Pure x) = return x
--return value if finished
trace (Free m) = do
    (log, st) <- get
    --get current log & state
    let (nextFree, st') = runState m st
    --run one state step inside the free structure. 
    put (st' : log, st')
    --record new state in log and update
    trace nextFree
    --trace remaining steps



{- Question 3 -}



step :: YieldState s () -> State s (Maybe (YieldState s ()))
--run a thread until it yields or finishes.
step (Pure _) =
    return Nothing
    --thread finished -> stop

step (Free (FLeft m)) = do
    next <- m
    --execute one state step.
    step next
    --continue until yeidl or fin.

step (Free (FRight (Yield cont))) =
    return (Just cont)
    --if yield hit, return cont.

roundRobin :: [YieldState s ()] -> State s ()
--full rr scheduler -> run first thread until yield/fin. rm fin. threads & move yielded ones to back
roundRobin [] = return ()
--no threads left
roundRobin (t:ts) = do
    r <- step t
    case r of
      Nothing   -> roundRobin ts
      --thread finished --> drop
      Just cont -> roundRobin (ts ++ [cont])
      --yielded --> move cont. to end



----------------------------------------------------------------------------------------------
-----------------------------------DEMO CODE FOR TEST Q3 FROM README.md-----------------------
----------------------------------------------------------------------------------------------



charWriter :: Char -> YieldState String ()
--write char into state string, yield control for thread switch & continue writing till string too long.
charWriter c = do
    s <- getY
    if length s > 10
        then pure ()
        else do
            putY (c:s)
            yield
            charWriter c
yieldExample = [charWriter 'a', charWriter 'b', charWriter 'c']



{- Question 4 -}



data ThreadResult s
  = ThreadDone
  --thread fin.
  | ThreadSleeping Int (SleepState s ())
  --thread sleep

decCounter :: (Int, a) -> (Int, a)
decCounter (n, x) = (if n > 0 then n - 1 else 0, x)
--decrement a sleep counter by 1 but not below 0.

runThread :: SleepState s ()
  -> [(Int, SleepState s ())]
  -> State s (ThreadResult s, [(Int, SleepState s ())])
--run thread until it reaches sleep or finishes, with each step advancing time for other threads
runThread (Pure ()) others =
  return (ThreadDone, others)

runThread (Free (FLeft m)) others = do
  next <- m
  --one state step in thread
  let others' = map decCounter others
  --time passing
  runThread next others'
  --continue running thread

runThread (Free (FRight (Sleep n cont))) others =
  return (ThreadSleeping n cont, others)
  --sleep encounter --> return sleep request.

schedule :: [SleepState s ()] -> State s ()
--rr scheduler with sleep support --> runnable threads run immediately, sleeping wait until counters are 0, fin. threads removed.
schedule threads0 = go (map (\t -> (0, t)) threads0)
  where
    go :: [(Int, SleepState s ())] -> State s ()
    go [] = return ()
    --no threads left.

    go ts =
      case findIndex (\(n, _) -> n == 0) ts of
        --find first runnable thread.
        Nothing ->
          let ts' = map decCounter ts
          in go ts'
          --nothing runnable --> advance time

        Just i ->
          let (before, rest) = splitAt i ts
          in case rest of
               [] -> go ts
               --safety case
               ((_, th) : after) -> do
                 let others = before ++ after
                 (res, others') <- runThread th others
                 case res of
                   ThreadDone ->
                     go others'
                     --remove fin. thead

                   ThreadSleeping n cont ->
                     let (before', after') = splitAt (length before) others'
                         ts' = before' ++ (n, cont) : after'
                     in go ts'
                     --re-insert sleeping thread with counter

--TODO: Fix short comments and explain better, especially q4 & 3
