{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Applicative properties
--
-- You will need @TypeApplications@ to use these.
module Test.Validity.Applicative
  ( applicativeSpec,
    applicativeSpecOnArbitrary,
    applicativeSpecOnGens,
  )
where

import Data.Data
import Data.GenValidity
import Data.Kind
import Test.Hspec
import Test.QuickCheck
import Test.Validity.Functions
import Test.Validity.Utils

{-# ANN module "HLint: ignore Avoid lambda" #-}

pureTypeStr ::
  forall (f :: Type -> Type).
  (Typeable f) =>
  String
pureTypeStr = unwords ["pure", "::", "a", "->", nameOf @f, "a"]

seqTypeStr ::
  forall (f :: Type -> Type).
  (Typeable f) =>
  String
seqTypeStr =
  unwords
    [ "(<*>)",
      "::",
      nameOf @f,
      "(a",
      "->",
      "b)",
      "->",
      nameOf @f,
      "a",
      "->",
      nameOf @f,
      "b"
    ]

seqrTypeStr ::
  forall (f :: Type -> Type).
  (Typeable f) =>
  String
seqrTypeStr =
  unwords
    [ "(*>)",
      "::",
      nameOf @f,
      "a",
      "->",
      nameOf @f,
      "b",
      "->",
      nameOf @f,
      "b"
    ]

seqlTypeStr ::
  forall (f :: Type -> Type).
  (Typeable f) =>
  String
seqlTypeStr =
  unwords
    [ "(<*)",
      "::",
      nameOf @f,
      "a",
      "->",
      nameOf @f,
      "b",
      "->",
      nameOf @f,
      "a"
    ]

-- | Standard test spec for properties of Applicative instances for values generated with GenValid instances
--
-- Example usage:
--
-- > applicativeSpecOnArbitrary @[]
applicativeSpec ::
  forall (f :: Type -> Type).
  ( Eq (f Int),
    Show (f Int),
    Applicative f,
    Typeable f,
    GenValid (f Int)
  ) =>
  Spec
applicativeSpec = applicativeSpecWithInts @f genValid

-- | Standard test spec for properties of Applicative instances for values generated with Arbitrary instances
--
-- Example usage:
--
-- > applicativeSpecOnArbitrary @[]
applicativeSpecOnArbitrary ::
  forall (f :: Type -> Type).
  (Eq (f Int), Show (f Int), Applicative f, Typeable f, Arbitrary (f Int)) =>
  Spec
applicativeSpecOnArbitrary = applicativeSpecWithInts @f arbitrary

applicativeSpecWithInts ::
  forall (f :: Type -> Type).
  (Show (f Int), Eq (f Int), Applicative f, Typeable f) =>
  Gen (f Int) ->
  Spec
applicativeSpecWithInts gen =
  applicativeSpecOnGens
    @f
    @Int
    genValid
    "int"
    gen
    (unwords [nameOf @f, "of ints"])
    gen
    (unwords [nameOf @f, "of ints"])
    ((+) <$> genValid)
    "increments"
    (pure <$> ((+) <$> genValid))
    (unwords [nameOf @f, "of increments"])
    (pure <$> ((*) <$> genValid))
    (unwords [nameOf @f, "of scalings"])

-- | Standard test spec for properties of Applicative instances for values generated by given generators (and names for those generator).
--
-- Unless you are building a specific regression test, you probably want to use the other 'applicativeSpec' functions.
--
-- Example usage:
--
-- > applicativeSpecOnGens
-- >     @Maybe
-- >     @String
-- >     (pure "ABC")
-- >     "ABC"
-- >     (Just <$> pure "ABC")
-- >     "Just an ABC"
-- >     (pure Nothing)
-- >     "purely Nothing"
-- >     ((++) <$> genValid)
-- >     "prepends"
-- >     (pure <$> ((++) <$> genValid))
-- >     "prepends in a Just"
-- >     (pure <$> (flip (++) <$> genValid))
-- >     "appends in a Just"
applicativeSpecOnGens ::
  forall (f :: Type -> Type) (a :: Type) (b :: Type) (c :: Type).
  ( Show a,
    Show (f a),
    Eq (f a),
    Show (f b),
    Eq (f b),
    Show (f c),
    Eq (f c),
    Applicative f,
    Typeable f,
    Typeable a,
    Typeable b,
    Typeable c
  ) =>
  Gen a ->
  String ->
  Gen (f a) ->
  String ->
  Gen (f b) ->
  String ->
  Gen (a -> b) ->
  String ->
  Gen (f (a -> b)) ->
  String ->
  Gen (f (b -> c)) ->
  String ->
  Spec
applicativeSpecOnGens gena genaname gen genname genb genbname genfa genfaname genffa genffaname genffb genffbname =
  parallel $
    describe ("Applicative " ++ nameOf @f) $ do
      describe (unwords [pureTypeStr @f, "and", seqTypeStr @f]) $ do
        it
          ( unwords
              [ "satisfy the identity law: 'pure id <*> v = v' for",
                genDescr @(f a) genname
              ]
          )
          $ equivalentOnGen (pure id <*>) id gen shrinkNothing
        it
          ( unwords
              [ "satisfy the composition law: 'pure (.) <*> u <*> v <*> w = u <*> (v <*> w)' for",
                genDescr @(f (b -> c)) genffbname,
                "composed with",
                genDescr @(f (a -> b)) genffaname,
                "and applied to",
                genDescr @(f a) genname
              ]
          )
          $ equivalentOnGens3
            ( \(Anon u) (Anon v) w ->
                pure (.) <*> (u :: f (b -> c)) <*> (v :: f (a -> b))
                  <*> (w :: f a) ::
                  f c
            )
            (\(Anon u) (Anon v) w -> u <*> (v <*> w) :: f c)
            ((,,) <$> (Anon <$> genffb) <*> (Anon <$> genffa) <*> gen)
            shrinkNothing
        it
          ( unwords
              [ "satisfy the homomorphism law: 'pure f <*> pure x = pure (f x)' for",
                genDescr @(a -> b) genfaname,
                "sequenced with",
                genDescr @a genaname
              ]
          )
          $ equivalentOnGens2
            (\(Anon f) x -> pure f <*> pure x :: f b)
            (\(Anon f) x -> pure $ f x :: f b)
            ((,) <$> (Anon <$> genfa) <*> gena)
            shrinkNothing
        it
          ( unwords
              [ "satisfy the interchange law: 'u <*> pure y = pure ($ y) <*> u' for",
                genDescr @(f (a -> b)) genffaname,
                "sequenced with",
                genDescr @a genaname
              ]
          )
          $ equivalentOnGens2
            (\(Anon u) y -> u <*> pure y :: f b)
            (\(Anon u) y -> pure ($ y) <*> u :: f b)
            ((,) <$> (Anon <$> genffa) <*> gena)
            shrinkNothing
        it
          ( unwords
              [ "satisfy the law about the functor instance: fmap f x = pure f <*> x for",
                genDescr @(a -> b) genfaname,
                "mapped over",
                genDescr @(f a) genname
              ]
          )
          $ equivalentOnGens2
            (\(Anon f) x -> fmap f x)
            (\(Anon f) x -> pure f <*> x)
            ((,) <$> (Anon <$> genfa) <*> gen)
            shrinkNothing
      describe (seqrTypeStr @f) $
        it
          ( unwords
              [ "is equivalent to its default implementation 'u Type> v = pure (const id) <*> u <*> v' for",
                genDescr @(f a) genname,
                "in front of",
                genDescr @b genbname
              ]
          )
          $ equivalentOnGens2
            (\u v -> u *> v)
            (\u v -> pure (const id) <*> u <*> v)
            ((,) <$> gen <*> genb)
            shrinkNothing
      describe (seqlTypeStr @f) $
        it
          ( unwords
              [ "is equivalent to its default implementation 'u <* v = pure const <*> u <*> v' for",
                genDescr @b genbname,
                "behind",
                genDescr @(f a) genname
              ]
          )
          $ equivalentOnGens2
            (\u v -> u <* v)
            (\u v -> pure const <*> u <*> v)
            ((,) <$> gen <*> genb)
            shrinkNothing
