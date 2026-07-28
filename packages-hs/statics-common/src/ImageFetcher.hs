-- | Downloads record images concurrently from PocketBase.
module ImageFetcher (
    ImageSource (..),
    downloadAllImages,
    downloadImage,
) where

import Control.Concurrent.Async (mapConcurrently)
import Control.Exception (SomeException, try)
import qualified Data.ByteString.Lazy as BL
import Data.Maybe (catMaybes)
import qualified Data.Text as T
import Network.HTTP.Simple (getResponseBody, getResponseStatusCode, httpLBS, parseRequest)

{- | How to read image information out of an app-specific record
(an event, a location, ...). Keeps this module independent of the
per-app PocketBase types.
-}
data ImageSource a = ImageSource
    { sourceId :: a -> String
    -- ^ Record id used in the destination filename and log messages.
    , sourceImage :: a -> Maybe T.Text
    -- ^ Image filename attached to the record, if any.
    , sourceImageUrl :: a -> T.Text -> String
    -- ^ Build the download URL for the record's image filename.
    , destDir :: FilePath
    -- ^ Local directory the images are written into (e.g. \"static/images\").
    }

{- | Download all record images concurrently.
Returns a list of (recordId, localFilePath) pairs for records with images.
-}
downloadAllImages :: ImageSource a -> [a] -> IO [(String, FilePath)]
downloadAllImages src records = do
    let withImages = [(r, T.unpack img) | r <- records, Just img <- [sourceImage src r]]
    results <- mapConcurrently (uncurry (downloadImage src)) withImages
    return (catMaybes results)

{- | Download a single record image.
Returns Nothing on failure (logs warning but does not abort).
-}
downloadImage :: ImageSource a -> a -> String -> IO (Maybe (String, FilePath))
downloadImage src r filename = do
    let url = sourceImageUrl src r (T.pack filename)
        dest = destDir src ++ "/" ++ sourceId src r ++ "_" ++ filename
    result <- try (fetchAndWrite url dest) :: IO (Either SomeException ())
    case result of
        Left err -> do
            putStrLn $ "Warning: Failed to download image for " ++ sourceId src r ++ ": " ++ show err
            return Nothing
        Right () ->
            return (Just (sourceId src r, dest))

fetchAndWrite :: String -> FilePath -> IO ()
fetchAndWrite url dest = do
    req <- parseRequest ("GET " ++ url)
    resp <- httpLBS req
    let status = getResponseStatusCode resp
    if status == 200
        then BL.writeFile dest (getResponseBody resp)
        else putStrLn $ "Warning: HTTP " ++ show status ++ " for " ++ url
