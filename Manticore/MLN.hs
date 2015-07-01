{-# LANGUAGE OverloadedStrings #-}

-- | Types and algorithms for Markov logic networks.
module Manticore.MLN where

import qualified Data.Map as Map
import Data.Map (Map)
import qualified Data.Set as Set
import Data.Set (Set)
import Manticore.FOL
import Manticore.Formula
import Manticore.Predicate
import Manticore.Term
import Manticore.Parser
import Manticore.Symbols
import Manticore.Network
import qualified Manticore.KB as KB
import Manticore.KB (KB)

-- | A Markov logic network is a set of first-order logical formulas associated
-- with a weight.
type MLN t = Map (FOL t) Double

-- | Prints a Markov logic network.
showMLN :: (Show t) => Symbols -> MLN t -> String
showMLN s = Map.foldrWithKey (\k v acc -> showWFormula s k v ++ "\n" ++ acc) ""

-- | Prints a weighted formula.
showWFormula :: (Show t) => Symbols -> FOL t -> Double -> String
showWFormula s f w = showW ++ replicate nSpaces ' ' ++ prettyPrintFm s f
  where
    showW = show w
    nSpaces = 24 - length showW

-- | Adds a formula to the markov logic network using the parser. If the parser
-- fails, the function returns the MLN unmodified.
tellS :: String -> Double -> MLN String -> MLN String
tellS s w mln = case parseFOL s of
  Left _  -> mln
  Right f -> Map.insert f w mln

-- | Gathers all the predicates of a markov logic network in a set.
allPredicates :: (Ord t) => MLN t -> Set (Predicate t)
allPredicates = Map.foldWithKey (\k _ acc -> Set.union (atoms k) acc) Set.empty

-- | Get all groundings from a Markov logic network.
allGroundings :: Map (String, [Term String]) (Term String) -> [Term String] -> MLN String -> KB (Predicate String)
allGroundings m ts mln = KB.allGroundings m ts (toKB mln)

-- | Builds a ground network for Markov logic.
groundNetwork :: Map (String, [Term String]) (Term String) -> [Term String] -> MLN String -> UNetwork (Predicate String)
groundNetwork m ts mln = Set.foldr' (\p acc -> Map.insert p (mb p) acc) Map.empty ps
  where
    -- All groundings from all formulas in the knowledge base:
    gs = Set.foldr' (\g acc -> Set.union (groundings m ts g) acc) Set.empty (Map.keysSet mln)
    -- All the predicates:
    ps = KB.allPredicates gs
    -- The Markov blanket of predicate 'p', that is: all its neighbours.
    mb p = Set.delete p $ KB.allPredicates $ Set.filter (hasPred p) gs

-- | Builds a weighted knowledge base from a list of strings. If the parser
-- fails to parse a formula, it is ignored.
fromStrings :: [String] -> MLN String
fromStrings = foldr
  (\k acc ->
    case parseWFOL k of
      Left _        -> acc
      Right (f, w)  -> Map.insert f w acc)
  Map.empty

-- | Converts a markov logic network to an unweighted knowledge base.
toKB :: (Ord t) => MLN t -> KB (Predicate t)
toKB = Map.keysSet
