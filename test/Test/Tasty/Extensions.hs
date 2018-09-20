{-# LANGUAGE AllowAmbiguousTypes   #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-|

Registry      : Test.Tasty.Extensions
Description : Tasty / Hedgehog / HUnit integration

This module unifies property based testing with Hedgehog
and one-off tests.

-}
module Test.Tasty.Extensions (
  module Hedgehog
, module Tasty
, gotException
, noShrink
, prop
, test
, minTestsOk
, withSeed
) where

import           Data.Maybe          (fromJust)
import           GHC.Stack
import           Hedgehog            as Hedgehog hiding (test)
import           Hedgehog.Corpus     as Hedgehog
import           Hedgehog.Gen        as Hedgehog hiding (discard, print)
import qualified Prelude             as Prelude
import           Protolude           hiding ((.&.))
import           Test.Tasty          as Tasty
import           Test.Tasty.Options  as Tasty
import           Test.Tasty.Hedgehog as Tasty
import           Test.Tasty.TH       as Tasty

-- | Create a Tasty test from a Hedgehog property
prop :: HasCallStack => TestName -> PropertyT IO () -> [TestTree]
prop name p = [withFrozenCallStack $ testProperty name (Hedgehog.property p)]

-- | Create a Tasty test from a Hedgehog property called only once
test :: HasCallStack => TestName -> PropertyT IO () -> [TestTree]
test name p = withFrozenCallStack (minTestsOk 1 . noShrink $ prop name p)

gotException :: forall a . (HasCallStack, Show a) => a -> PropertyT IO ()
gotException a = withFrozenCallStack $ do
  res <- liftIO (try (evaluate a) :: IO (Either SomeException a))
  case res of
    Left _  -> assert True
    Right _ -> annotateShow ("excepted an exception" :: Text) >> assert False

-- * Parameters

minTestsOk :: Int -> [TestTree] -> [TestTree]
minTestsOk n = fmap (localOption (HedgehogTestLimit (Just (toEnum n :: TestLimit))))

noShrink :: [TestTree] -> [TestTree]
noShrink = fmap (localOption (HedgehogShrinkLimit (Just (0 :: ShrinkLimit))))

withSeed :: Prelude.String -> [TestTree] -> [TestTree]
withSeed seed = fmap (localOption (fromJust (parseValue seed :: Maybe HedgehogReplay)))
