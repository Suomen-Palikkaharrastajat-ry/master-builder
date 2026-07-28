module Geocoding exposing
    ( GeoPoint
    , decodeGeocodeResponse
    , decodeReverseGeocode
    , geocode
    , reverseGeocode
    )

{-| Geocoding and reverse geocoding via the Nominatim (OpenStreetMap) API.

`GeoPoint` is a structural alias (`{ lat : Float, lon : Float }`), so it
unifies with an identical alias defined in the consuming application.

-}

import Http
import Json.Decode as Json exposing (Decoder)
import Url


type alias GeoPoint =
    { lat : Float
    , lon : Float
    }


nominatimBase : String
nominatimBase =
    "https://nominatim.openstreetmap.org"


userAgent : Http.Header
userAgent =
    Http.header "User-Agent" "SuomenPalikkaharrastajat/1.0"


{-| Geocode a location name to coordinates via Nominatim.
-}
geocode : String -> (Result Http.Error (Maybe GeoPoint) -> msg) -> Cmd msg
geocode locationName toMsg =
    Http.request
        { method = "GET"
        , headers = [ userAgent ]
        , url =
            nominatimBase
                ++ "/search"
                ++ "?q="
                ++ Url.percentEncode locationName
                ++ "&format=json&limit=1"
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg decodeGeocodeResponse
        , timeout = Just 10000
        , tracker = Nothing
        }


{-| Reverse geocode coordinates to a place name via Nominatim.
-}
reverseGeocode : Float -> Float -> (Result Http.Error String -> msg) -> Cmd msg
reverseGeocode lat lon toMsg =
    Http.request
        { method = "GET"
        , headers = [ userAgent ]
        , url =
            nominatimBase
                ++ "/reverse"
                ++ "?lat="
                ++ String.fromFloat lat
                ++ "&lon="
                ++ String.fromFloat lon
                ++ "&format=json"
        , body = Http.emptyBody
        , expect = Http.expectJson toMsg decodeReverseGeocode
        , timeout = Just 10000
        , tracker = Nothing
        }



-- DECODERS


decodeGeocodeResponse : Decoder (Maybe GeoPoint)
decodeGeocodeResponse =
    Json.list decodeGeocodingResult
        |> Json.map
            (List.head
                >> Maybe.map (\r -> { lat = r.lat, lon = r.lon })
            )


type alias GeocodingResult =
    { lat : Float
    , lon : Float
    , displayName : String
    }


decodeGeocodingResult : Decoder GeocodingResult
decodeGeocodingResult =
    Json.map3 GeocodingResult
        (Json.field "lat" decodeStringFloat)
        (Json.field "lon" decodeStringFloat)
        (Json.field "display_name" Json.string)


{-| Nominatim returns lat/lon as strings, not numbers.
-}
decodeStringFloat : Decoder Float
decodeStringFloat =
    Json.string
        |> Json.andThen
            (\s ->
                case String.toFloat s of
                    Just f ->
                        Json.succeed f

                    Nothing ->
                        Json.fail ("Expected a float string, got: " ++ s)
            )


decodeReverseGeocode : Decoder String
decodeReverseGeocode =
    Json.field "display_name" Json.string
