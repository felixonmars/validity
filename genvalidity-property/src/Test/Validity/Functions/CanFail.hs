{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Validity.Functions.CanFail
  ( succeedsOnGen,
    succeeds,
    succeedsOnArbitrary,
    succeedsOnGens2,
    succeeds2,
    succeedsOnArbitrary2,
    failsOnGen,
    failsOnGens2,
    validIfSucceedsOnGen,
    validIfSucceedsOnArbitrary,
    validIfSucceeds,
    validIfSucceedsOnGens2,
    validIfSucceeds2,
    validIfSucceedsOnArbitrary2,
    validIfSucceedsOnGens3,
    validIfSucceeds3,
    validIfSucceedsOnArbitrary3,
  )
where

import Data.GenValidity
import Test.Hspec
import Test.QuickCheck
import Test.Validity.Property.Utils
import Test.Validity.Types

-- | The function succeeds if the input is generated by the given generator
succeedsOnGen ::
  (Show a, Show (f b), CanFail f) => (a -> f b) -> Gen a -> (a -> [a]) -> Property
succeedsOnGen func gen s = forAllShrink gen s $ \a -> func a `shouldSatisfy` (not . hasFailed)

-- | The function succeeds if the input is generated by @genValid@
succeeds :: (Show a, Show (f b), GenValid a, CanFail f) => (a -> f b) -> Property
succeeds f = succeedsOnGen f genValid shrinkValid

-- | The function succeeds if the input is generated by @arbitrary@
succeedsOnArbitrary ::
  (Show a, Show (f b), Arbitrary a, CanFail f) => (a -> f b) -> Property
succeedsOnArbitrary f = succeedsOnGen f arbitrary shrink

-- | The function fails if the input is generated by the given generator
failsOnGen ::
  (Show a, Show (f b), CanFail f) => (a -> f b) -> Gen a -> (a -> [a]) -> Property
failsOnGen func gen s = forAllShrink gen s $ \a -> func a `shouldSatisfy` hasFailed

-- | The function produces output that satisfies @isValid@ if it is given input
-- that is generated by the given generator.
validIfSucceedsOnGen ::
  (Show a, Show b, Validity b, CanFail f) => (a -> f b) -> Gen a -> (a -> [a]) -> Property
validIfSucceedsOnGen func gen s =
  forAllShrink gen s $ \a ->
    case resultIfSucceeded (func a) of
      Nothing -> return () -- Can happen
      Just res -> shouldBeValid res

-- | The function produces output that satisfies @isValid@ if it is given input
-- that is generated by @arbitrary@.
validIfSucceedsOnArbitrary ::
  (Show a, Show b, Arbitrary a, Validity b, CanFail f) => (a -> f b) -> Property
validIfSucceedsOnArbitrary f = validIfSucceedsOnGen f arbitrary shrink

-- | The function produces output that satisfies @isValid@ if it is given input
-- that is generated by @genValid@.
validIfSucceeds :: (Show a, Show b, GenValid a, Validity b, CanFail f) => (a -> f b) -> Property
validIfSucceeds f = validIfSucceedsOnGen f genValid shrinkValid

succeedsOnGens2 ::
  (Show a, Show b, Show (f c), CanFail f) =>
  (a -> b -> f c) ->
  Gen (a, b) ->
  ((a, b) -> [(a, b)]) ->
  Property
succeedsOnGens2 func gen s =
  forAllShrink gen s $ \(a, b) -> func a b `shouldSatisfy` (not . hasFailed)

succeeds2 ::
  (Show a, Show b, Show (f c), GenValid a, GenValid b, CanFail f) =>
  (a -> b -> f c) ->
  Property
succeeds2 func = succeedsOnGens2 func genValid shrinkValid

succeedsOnArbitrary2 ::
  (Show a, Show b, Show (f c), Arbitrary a, Arbitrary b, CanFail f) =>
  (a -> b -> f c) ->
  Property
succeedsOnArbitrary2 func = succeedsOnGens2 func arbitrary shrink

failsOnGens2 ::
  (Show a, Show b, Show (f c), CanFail f) =>
  (a -> b -> f c) ->
  Gen a ->
  (a -> [a]) ->
  Gen b ->
  (b -> [b]) ->
  Property
failsOnGens2 func genA sA genB sB =
  forAllShrink genA sA $ \a -> forAllShrink genB sB $ \b -> func a b `shouldSatisfy` hasFailed

validIfSucceedsOnGens2 ::
  (Show a, Show b, Show c, Validity c, CanFail f) =>
  (a -> b -> f c) ->
  Gen (a, b) ->
  ((a, b) -> [(a, b)]) ->
  Property
validIfSucceedsOnGens2 func gen s =
  forAllShrink gen s $ \(a, b) ->
    case resultIfSucceeded (func a b) of
      Nothing -> return () -- Can happen
      Just res -> shouldBeValid res

validIfSucceeds2 ::
  (Show a, Show b, Show c, GenValid a, GenValid b, Validity c, CanFail f) =>
  (a -> b -> f c) ->
  Property
validIfSucceeds2 func = validIfSucceedsOnGens2 func genValid shrinkValid

validIfSucceedsOnArbitrary2 ::
  (Show a, Show b, Show c, Arbitrary a, Arbitrary b, Validity c, CanFail f) =>
  (a -> b -> f c) ->
  Property
validIfSucceedsOnArbitrary2 func = validIfSucceedsOnGens2 func arbitrary shrink

validIfSucceedsOnGens3 ::
  (Show a, Show b, Show c, Show d, Validity d, CanFail f) =>
  (a -> b -> c -> f d) ->
  Gen (a, b, c) ->
  ((a, b, c) -> [(a, b, c)]) ->
  Property
validIfSucceedsOnGens3 func gen s =
  forAllShrink gen s $ \(a, b, c) ->
    case resultIfSucceeded (func a b c) of
      Nothing -> return () -- Can happen
      Just res -> shouldBeValid res

validIfSucceeds3 ::
  ( Show a,
    Show b,
    Show c,
    Show d,
    GenValid a,
    GenValid b,
    GenValid c,
    Validity d,
    CanFail f
  ) =>
  (a -> b -> c -> f d) ->
  Property
validIfSucceeds3 func = validIfSucceedsOnGens3 func genValid shrinkValid

validIfSucceedsOnArbitrary3 ::
  (Show a, Show b, Show c, Show d, Arbitrary a, Arbitrary b, Arbitrary c, Validity d, CanFail f) =>
  (a -> b -> c -> f d) ->
  Property
validIfSucceedsOnArbitrary3 func = validIfSucceedsOnGens3 func arbitrary shrink
