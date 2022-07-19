{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Data.GenValidity.URI where

import Control.Monad
import Data.Char
import Data.Char as Char
import Data.GenValidity
import Data.List
import Data.Validity.URI ()
import Data.Word
import Network.URI
import Test.QuickCheck

instance GenValid URIAuth where
  genValid = (`suchThat` isValid) $ do
    uriUserInfo <- nullOrAppend '@' <$> genURIComponentString

    uriRegName <- genURIStringSeparatedBy '.'

    port <- genValid :: Gen Word16
    let uriPort = ':' : show port

    pure $ rectifyAuth URIAuth {..}

instance GenValid URI where
  genValid = (`suchThat` isValid) $ do
    uriScheme <- genScheme

    uriAuthority <- genValid

    uriPath <- nullOrPrepend '/' <$> genURIStringSeparatedBy '/'

    uriQuery <- nullOrAppend '?' <$> genURIStringSeparatedBy '&'

    uriFragment <- nullOrPrepend '#' <$> genURIComponentString

    pure $ rectify URI {..}

genScheme :: Gen String
genScheme = nullOrAppend ':' <$> genSchemeString

genSchemeString :: Gen String
genSchemeString =
  genStringBy $
    oneof
      [ genCharALPHA,
        genCharDIGIT,
        elements ['+', '-', '.']
      ]

genCharALPHA :: Gen Char
genCharALPHA =
  Char.chr
    <$> oneof
      [ choose (0x41, 0x5A),
        choose (0x61, 0x7A)
      ]

genCharDIGIT :: Gen Char
genCharDIGIT =
  Char.chr
    <$> choose (0x30, 0x39)

-- genURI :: Gen URI
-- genURI = undefined
--
-- genURIReference :: Gen URI
-- genURIReference = undefined
--
-- genRelativeReference :: Gen URI
-- genRelativeReference = undefined
--
-- genAbsoluteURI :: Gen URI
-- genAbsoluteURI = undefined

-- [RFC 3986 section 1.2.1](https://datatracker.ietf.org/doc/html/rfc3986#section-1.2.1)
--
-- @
-- The URI syntax has been designed with global transcription as one of
-- its main considerations.  A URI is a sequence of characters from a
-- very limited set: the letters of the basic Latin alphabet, digits,
-- and a few special characters.
-- @
genURIChar :: Gen Char
genURIChar =
  (chr <$> choose (0, 127)) `suchThat` isAllowedInURI

genURIString :: Gen String
genURIString = genListOf genURIChar

genURIComponentString :: Gen String
genURIComponentString = escapeURIString isUnescapedInURIComponent <$> genListOf genURIChar

genURIStringSeparatedBy :: Char -> Gen String
genURIStringSeparatedBy c = do
  ll <- (`div` 5) . max 1 <$> genListLength
  intercalate [c] <$> replicateM ll (escapeURIString isUnescapedInURIComponent <$> genURIComponentString)

nullOrAppend :: Char -> String -> String
nullOrAppend c s = if null s then s else s ++ [c]

nullOrPrepend :: Char -> String -> String
nullOrPrepend c s = if null s then s else c : s
