{-@ LIQUID "--reflection" @-}
{-@ LIQUID "--ple"        @-}

module Leadbeater.Network where

import Prelude hiding
  ( all
  , and
  , any
  , drop
  , foldr
  , length
  , map
  , or
  , replicate
  , sum
  , take
  , zipWith
  )

import           Leadbeater.LinearAlgebra
import qualified Leadbeater.LinearAlgebra.Internal
import           Leadbeater.Prelude (R)
import qualified Leadbeater.Prelude


-- * Activation functions

data Activation
   = ReLu
   | Softmax
   | Sigmoid
   deriving (Eq)


-- * Layers

data Layer = Layer
   { bias       :: !R
   , weights    :: Matrix R
   , activation :: Activation
   }
   deriving (Eq)

{-@
data Layer = Layer
   { bias       :: R
   , weights    :: Matrix R
   , activation :: Activation
   }
@-}

{-@ reflect layerInputs @-}
{-@ layerInputs :: Layer -> Nat @-}
layerInputs :: Layer -> Int
layerInputs l = rows (weights l)

{-@ reflect layerOutputs @-}
{-@ layerOutputs :: Layer -> Nat @-}
layerOutputs :: Layer -> Int
layerOutputs l = cols (weights l)

{-@ type LayerN I O = {l:Layer | I = layerInputs l && O = layerOutputs l} @-}
{-@ type LayerX X   = LayerN (layerInputs X) (layerOutputs X) @-}

{-@ reflect runLayer @-}
{-@ runLayer :: l:Layer -> VectorN R (layerInputs l) -> VectorN R (layerOutputs l) @-}
runLayer :: Layer -> Vector R -> Vector R
runLayer l v = bias l +> (v <# weights l)


-- * Networks

data Network
   = NLast { nLast :: Layer }
   | NStep { nHead :: Layer, nTail :: Network }

{-@ reflect networkInputs @-}
{-@ networkInputs :: Network -> Nat @-}
networkInputs :: Network -> Int
networkInputs (NLast l)   = layerInputs l
networkInputs (NStep l _) = layerInputs l

{-@ reflect networkOutputs @-}
{-@ networkOutputs :: Network -> Nat @-}
networkOutputs :: Network -> Int
networkOutputs (NLast l)   = layerOutputs l
networkOutputs (NStep _ n) = networkOutputs n

{-@ type NetworkN I O = {n:Network | networkInputs n == I && networkOutputs n == O} @-}
{-@ type NetworkX L   = {n:Network | layerOutputs L == networkInputs n} @-}

{-@
data Network
   = NLast { nLast :: Layer }
   | NStep { nHead :: Layer, nTail :: NetworkX nHead }
@-}

{-@ reflect runNetwork @-}
{-@ runNetwork :: n:Network -> VectorN R (networkInputs n) -> VectorN R (networkOutputs n) @-}
runNetwork :: Network -> Vector R -> Vector R
runNetwork (NLast l)   xs = runLayer l xs
runNetwork (NStep l n) xs = runNetwork n (runLayer l xs)
