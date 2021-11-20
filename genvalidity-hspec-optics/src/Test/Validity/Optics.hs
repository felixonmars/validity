{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Standard test `Spec`s for optics
module Test.Validity.Optics
  ( lensSpec,
    lensSpecOnArbitrary,
    lensSpecOnGen,
    lensLaw1,
    lensLaw2,
    lensLaw3,
    lensGettingProducesValid,
    lensGettingProducesValidOnArbitrary,
    lensGettingProducesValidOnGen,
    lensSettingProducesValid,
    lensSettingProducesValidOnArbitrary,
    lensSettingProducesValidOnGen,
  )
where

import Data.GenValidity
import Lens.Micro
import Lens.Micro.Extras
import Test.Hspec
import Test.QuickCheck
import Test.Validity.Utils

-- | Standard test spec for properties lenses for valid values
--
-- Example usage:
--
-- > lensSpec ((_2) :: Lens (Int, Int) (Int, Int) Int Int)
lensSpec ::
  forall s b.
  ( Show b,
    Eq b,
    GenValid b,
    Show s,
    Eq s,
    GenValid s
  ) =>
  Lens s s b b ->
  Spec
lensSpec l =
  lensSpecOnGen
    l
    (genValid @b)
    "valid values"
    shrinkValid
    (genValid @s)
    "valid values"
    shrinkValid

-- | Standard test spec for properties lenses for arbitrary values
--
-- Example usage:
--
-- > lensSpecOnArbitrary ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational)
lensSpecOnArbitrary ::
  forall s b.
  ( Show b,
    Eq b,
    Arbitrary b,
    Validity b,
    Show s,
    Eq s,
    Arbitrary s,
    Validity s
  ) =>
  Lens s s b b ->
  Spec
lensSpecOnArbitrary l =
  lensSpecOnGen
    l
    (arbitrary @b)
    "arbitrary values"
    shrink
    (arbitrary @s)
    "arbitrary values"
    shrink

-- | Standard test spec for properties lenses for values generated by given generators
--
-- Example usage:
--
-- > lensSpecOnGen
-- >      ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational)
-- >      (abs <$> genValid)
-- >      "positive valid doubles"
-- >      (filter (0.0 >=) . shrinkValid)
-- >      ((,) <$> (negate . abs <$> genValid) <*> (negate . abs <$> genValid))
-- >      "tuples of negative valid doubles"
-- >      (const [])
lensSpecOnGen ::
  (Show b, Eq b, Validity b, Show s, Eq s, Validity s) =>
  Lens s s b b ->
  Gen b ->
  String ->
  (b -> [b]) ->
  Gen s ->
  String ->
  (s -> [s]) ->
  Spec
lensSpecOnGen l genB genBName shrinkB genS genSName shrinkS = do
  parallel $ do
    it
      ( unwords
          ["satisfies the first lens law for", genBName, "and", genSName]
      )
      $ lensLaw1 l genB shrinkB genS shrinkS
    it (unwords ["satisfies the second lens law for", genSName]) $
      lensLaw2 l genS shrinkS
    it
      ( unwords
          ["satisfies the third lens law for", genBName, "and", genSName]
      )
      $ lensLaw3 l genB shrinkB genS shrinkS
    it (unwords ["gets valid values from", genSName, "values"]) $
      lensGettingProducesValidOnGen l genS shrinkS
    it
      ( unwords
          [ "produces valid values when it is used to set",
            genBName,
            "values on",
            genSName,
            "values"
          ]
      )
      $ lensSettingProducesValidOnGen l genB shrinkB genS shrinkS

-- | A property combinator for the first lens law:
--
-- > view l (set l v s)  ≡ v
--
-- Example usage:
--
-- prop> lensLaw1 ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational) genValid shrinkValid genValid shrinkValid
lensLaw1 ::
  (Show b, Eq b, Show s) =>
  Lens s s b b ->
  Gen b ->
  (b -> [b]) ->
  Gen s ->
  (s -> [s]) ->
  Property
lensLaw1 l genB shrinkB genS shrinkS =
  forAllShrink genB shrinkB $ \b ->
    forAllShrink genS shrinkS $ \s -> view l (set l b s) `shouldBe` b

-- | A property combinator for the second lens law:
--
-- > set l (view l s) s  ≡ s
--
-- Example usage:
--
-- prop> lensLaw2 ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational) genValid shrinkValid
lensLaw2 :: (Show s, Eq s) => Lens s s b b -> Gen s -> (s -> [s]) -> Property
lensLaw2 l genS shrinkS =
  forAllShrink genS shrinkS $ \s -> set l (view l s) s `shouldBe` s

-- | A property combinator for the third lens law:
--
-- > set l v' (set l v s) ≡ set l v' s
--
-- Example usage:
--
-- prop> lensLaw3 ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational) genValid shrinkValid genValid shrinkValid
lensLaw3 ::
  (Show b, Show s, Eq s) =>
  Lens s s a b ->
  Gen b ->
  (b -> [b]) ->
  Gen s ->
  (s -> [s]) ->
  Property
lensLaw3 l genB shrinkB genS shrinkS =
  forAllShrink genB shrinkB $ \b ->
    forAllShrink genB shrinkB $ \b' ->
      forAllShrink genS shrinkS $ \s ->
        set l b' (set l b s) `shouldBe` set l b' s

-- | A property combinator to test whether getting values via a lens on valid values produces valid values.
--
-- Example Usage:
--
-- prop> lensGettingProducesValid ((_2) :: Lens (Int, Int) (Int, Int) Int Int)
lensGettingProducesValid ::
  (Show s, GenValid s, Show b, Validity b) => Lens s s b b -> Property
lensGettingProducesValid l =
  lensGettingProducesValidOnGen l genValid shrinkValid

-- | A property combinator to test whether getting values via a lens on arbitrary values produces valid values.
--
-- Example Usage:
--
-- prop> lensGettingProducesValidOnArbitrary ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational)
lensGettingProducesValidOnArbitrary ::
  (Show s, Arbitrary s, Show b, Validity b) =>
  Lens s s b b ->
  Property
lensGettingProducesValidOnArbitrary l =
  lensGettingProducesValidOnGen l arbitrary shrink

-- | A property combinator to test whether getting values generated by given a generator via a lens on values generated by a given generator produces valid values.
--
-- > isValid (view l s)
--
-- Example Usage:
--
-- prop> lensGettingProducesValidOnGen ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational) genValid shrinkValid
lensGettingProducesValidOnGen ::
  (Validity b, Show b, Show s) =>
  Lens s s b b ->
  Gen s ->
  (s -> [s]) ->
  Property
lensGettingProducesValidOnGen l genS shrinkS =
  forAllShrink genS shrinkS $ \s -> shouldBeValid $ view l s

-- | A property combinator to test whether setting valid values via a lens on valid values produces valid values.
--
-- Example usage:
--
-- prop> lensSettingProducesValid ((_2) :: Lens (Int, Int) (Int, Int) Int Int)
lensSettingProducesValid ::
  (Show s, GenValid s, Show b, GenValid b, Show t, Validity t) =>
  Lens s t a b ->
  Property
lensSettingProducesValid l =
  lensSettingProducesValidOnGen
    l
    genValid
    shrinkValid
    genValid
    shrinkValid

-- | A property combinator to test whether setting arbitrary values via a lens on arbitrary values produces valid values.
--
-- Example usage:
--
-- prop> lensSettingProducesValidOnArbitrary ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational)
lensSettingProducesValidOnArbitrary ::
  (Show s, Arbitrary s, Show b, Arbitrary b, Show t, Validity t) =>
  Lens s t a b ->
  Property
lensSettingProducesValidOnArbitrary l =
  lensSettingProducesValidOnGen l arbitrary shrink arbitrary shrink

-- | A property combinator to test whether setting values generated by given a generator via a lens on values generated by a given generator produces valid values.
--
-- > isValid (set l b s)
--
-- Example usage:
--
-- prop> lensSettingProducesValidOnGen ((_2) :: Lens (Rational, Rational) (Rational, Rational) Rational Rational) genValid shrinkValid genValid shrinkValid
lensSettingProducesValidOnGen ::
  (Show s, Show b, Show t, Validity t) =>
  Lens s t a b ->
  Gen b ->
  (b -> [b]) ->
  Gen s ->
  (s -> [s]) ->
  Property
lensSettingProducesValidOnGen l genB shrinkB genS shrinkS =
  forAllShrink genS shrinkS $ \s ->
    forAllShrink genB shrinkB $ \b -> shouldBeValid $ set l b s
