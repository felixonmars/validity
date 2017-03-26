{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

-- | Hashable properties
--
-- You will need @TypeApplications@ to use these.
module Test.Validity.Hashable
    ( hashableSpecOnValid
    , hashableSpecOnInvalid
    , hashableSpec
    , hashableSpecOnArbitrary
    , hashableSpecOnGen
    ) where

import Data.Data
import Data.Hashable
import Control.Monad
import Test.Validity.Utils

import Data.GenValidity

import Test.Hspec
import Test.QuickCheck

-- | Standard test spec for properties of Hashable instances for valid values
--
-- Example usage:
--
-- > hashableSpecOnValid @Double
hashableSpecOnValid
    :: forall a.
       (Show a, Eq a, Typeable a, GenValid a, Hashable a)
    => Spec
hashableSpecOnValid = hashableSpecOnGen @a genValid "valid"

-- | Standard test spec for properties of Hashable instances for invalid values
--
-- Example usage:
--
-- > hashableSpecOnInvalid @Double
hashableSpecOnInvalid
    :: forall a.
       (Show a, Eq a, Typeable a, GenInvalid a, Hashable a)
    => Spec
hashableSpecOnInvalid = hashableSpecOnGen @a genInvalid "invalid"

-- | Standard test spec for properties of Hashable instances for unchecked values
--
-- Example usage:
--
-- > hashableSpec @Int
hashableSpec
    :: forall a.
       (Show a, Eq a, Typeable a, GenUnchecked a, Hashable a)
    => Spec
hashableSpec = hashableSpecOnGen @a genUnchecked "unchecked"

-- | Standard test spec for properties of Hashable instances for arbitrary values
--
-- Example usage:
--
-- > hashableSpecOnArbitrary @Int
hashableSpecOnArbitrary
    :: forall a.
       (Show a, Eq a, Typeable a, Arbitrary a, Hashable a)
    => Spec
hashableSpecOnArbitrary = hashableSpecOnGen @a arbitrary "arbitrary"

-- | Standard test spec for properties of Hashable instances for values generated by a given generator (and name for that generator).
--
-- Example usage:
--
-- > hashableSpecOnGen ((* 2) <$> genValid @Int) "even"
hashableSpecOnGen
    :: forall a.
       (Show a, Eq a, Typeable a, Hashable a)
    => Gen a -> String -> Spec
hashableSpecOnGen gen genname =
    parallel $ do
        let name = nameOf @a
            hashablestr = (unwords
                            ["hashWithSalt :: Int ->"
                            , name
                            , "-> Int"])
            -- == "hashWithSalt :: Int -> a -> Int" for the specific a
            gen2 = (,) <$> gen <*> gen
        describe ("Hashable " ++ name) $ do
            describe hashablestr $ do
                it
                    (unwords
                         [ "satisfies (a == b) => (hashWithSalt n a) =="
                         ,"(hashWithSalt n b), for every n and for"
                         , genname
                         , name
                         ]) $
                    forAll gen2 $ \(a1, a2) ->
                        forAll arbitrary $ \int ->
                            when (a1 == a2) $
                                let hash = hashWithSalt int
                                in hash a1 `shouldBe` hash a2

