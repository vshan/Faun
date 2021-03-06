-- | Faun.Fuzzy is a fun functional set of functions for fuzzy sets.
module Faun.FuzzySet
( FuzzySet(..)
, fromSet
, subsetOf
, elementOf
, support
, singleton
, union
, intersection
, complement
, concentration
, dilation
, normalization
, size
, supportSize
, remove0s
) where

import qualified Data.Map.Strict as Map
import Data.Map (Map)
import qualified Data.Set as Set
import Data.Set (Set)
import qualified Data.Text as T
import Faun.Utils
import Faun.ShowTxt
import Faun.PrettyPrint

-- | A fuzzy set represented as a map from elements (text) to their degree.
data FuzzySet = FuzzySet (Map T.Text Double)
    deriving (Eq)

instance Show FuzzySet where
  show = T.unpack . showByElem

instance ShowTxt FuzzySet where
  showTxt = showByElem

instance PrettyPrint FuzzySet where
  prettyPrint _ = showByElem

-- | Number of elements in the fuzzyset.
size :: FuzzySet -> Int
size (FuzzySet m) = Map.size m

showByElem :: FuzzySet -> T.Text
showByElem (FuzzySet m) = T.concat ["{", txt, "}"]
  where elems = Map.toList m
        txt = T.intercalate ", " $ map (\(k, v) -> T.concat [k, "/", T.pack $ show v]) elems

-- | Converts a normal set into a fuzzyset with degree 1.0 for all elements.
fromSet :: Set T.Text -> FuzzySet
fromSet s = FuzzySet $ Set.foldr' (\k acc -> Map.insert k 1.0 acc) Map.empty s

-- | A set f0 is a subset of f1 if, for all elements, degree(e0) < degree(e1).
subsetOf :: FuzzySet -> FuzzySet -> Bool
subsetOf (FuzzySet m0) (FuzzySet m1) = allKeyVal sub m0
  where sub k v = case Map.lookup k m1 of Just v1 -> v < v1; Nothing -> False

-- | This one is tricky: in fuzzy set F, e ∈ F iff e has a degree of 1.0 in F.
elementOf :: T.Text -> FuzzySet -> Bool
elementOf e (FuzzySet m) = case Map.lookup e m of Just 1.0 -> True; _ -> False

-- | The set of members with a degree greater than 0.
support :: FuzzySet -> Set T.Text
support (FuzzySet m) = Map.keysSet $ Map.filter (> 0.0) m

-- | Number of elements with a degree greater than 0.
supportSize :: FuzzySet -> Int -- Integral?
supportSize = Set.size . support

-- | Removes elements with a degree of 0.   -- size $ removes0 === support
remove0s :: FuzzySet -> FuzzySet
remove0s (FuzzySet m) = FuzzySet $ Map.filter (> 0.0) m

-- | Tests whether the fuzzy set is a singleton (has a support of 1).
singleton :: FuzzySet -> Bool
singleton f = Set.size (support f) == 1

-- | Union of two fuzzy sets (taking the max value).
union :: FuzzySet -> FuzzySet -> FuzzySet
union (FuzzySet m0) (FuzzySet m1) = FuzzySet $ Map.unionWith max m0 m1

-- | Intersection of two fuzzy sets (taking the min value).
intersection :: FuzzySet -> FuzzySet -> FuzzySet
intersection (FuzzySet m0) (FuzzySet m1) = FuzzySet $ Map.intersectionWith min m0 m1

-- | The complement of a fuzzy set.
complement :: FuzzySet -> FuzzySet
complement (FuzzySet m) = FuzzySet $ Map.map (1.0 -) m

-- | Square all degrees.
concentration :: FuzzySet -> FuzzySet
concentration (FuzzySet m) = FuzzySet $ Map.map (**2) m

-- | Takes the square roots of all degrees.
dilation :: FuzzySet -> FuzzySet
dilation (FuzzySet m) = FuzzySet $ Map.map sqrt m

-- | Normalize degrees.
normalization :: FuzzySet -> FuzzySet
normalization (FuzzySet m) = FuzzySet $ Map.map (/ maxv) m
  where maxv = maxVal m
