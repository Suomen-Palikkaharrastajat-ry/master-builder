module Api exposing (routes)

{-| elm-pages API route definitions.
-}

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import Color
import Config
import FatalError exposing (FatalError)
import Html exposing (Html)
import LanguageTag
import LanguageTag.Language
import LanguageTag.Region
import MimeType
import Pages.Manifest as Manifest
import Pages.Url
import Route exposing (Route)
import UrlPath


-- Must match [site].url in content/config.toml.
-- Manifest.generator requires a plain String so this cannot be read from config at build time.
siteUrl : String
siteUrl =
    "https://logo.palikkaharrastajat.fi"


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ Manifest.generator siteUrl manifestConfig
    ]


manifestConfig : BackendTask FatalError Manifest.Config
manifestConfig =
    Config.task
        |> BackendTask.map
            (\config ->
                let
                    subtags =
                        LanguageTag.emptySubtags

                    pwa =
                        config.pwa
                in
                Manifest.init
                    { name = pwa.applicationName
                    , description = pwa.description
                    , startUrl = UrlPath.fromString pwa.startUrl
                    , icons =
                        [ { src = Pages.Url.external pwa.icons.icon192
                          , sizes = [ ( 192, 192 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeAny ]
                          }
                        , { src = Pages.Url.external pwa.icons.icon512
                          , sizes = [ ( 512, 512 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeAny ]
                          }
                        , { src = Pages.Url.external pwa.icons.maskableIcon
                          , sizes = [ ( 512, 512 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeMaskable ]
                          }
                        ]
                    }
                    |> Manifest.withShortName pwa.shortName
                    |> Manifest.withDisplayMode (displayModeFromString pwa.display)
                    |> Manifest.withBackgroundColor (colorFromHex pwa.backgroundColor)
                    |> Manifest.withThemeColor (colorFromHex pwa.themeColor)
                    |> Manifest.withLang
                        (LanguageTag.Language.fi
                            |> LanguageTag.build
                                { subtags | region = Just LanguageTag.Region.fi }
                        )
            )


displayModeFromString : String -> Manifest.DisplayMode
displayModeFromString display =
    case display of
        "fullscreen" ->
            Manifest.Fullscreen

        "minimal-ui" ->
            Manifest.MinimalUi

        "browser" ->
            Manifest.Browser

        _ ->
            Manifest.Standalone


colorFromHex : String -> Color.Color
colorFromHex hex =
    case hexToRgb hex of
        Just ( red, green, blue ) ->
            Color.rgb255 red green blue

        Nothing ->
            Color.rgb255 255 255 255


hexToRgb : String -> Maybe ( Int, Int, Int )
hexToRgb hex =
    let
        normalized =
            String.dropLeft (if String.startsWith "#" hex then 1 else 0) hex
    in
    if String.length normalized == 6 then
        Maybe.map3
            (\red green blue -> ( red, green, blue ))
            (hexPairToInt (String.slice 0 2 normalized))
            (hexPairToInt (String.slice 2 4 normalized))
            (hexPairToInt (String.slice 4 6 normalized))

    else
        Nothing


hexPairToInt : String -> Maybe Int
hexPairToInt pair =
    case String.toList pair of
        [ left, right ] ->
            Maybe.map2 (\a b -> (a * 16) + b) (hexCharToInt left) (hexCharToInt right)

        _ ->
            Nothing


hexCharToInt : Char -> Maybe Int
hexCharToInt char =
    case char of
        '0' ->
            Just 0

        '1' ->
            Just 1

        '2' ->
            Just 2

        '3' ->
            Just 3

        '4' ->
            Just 4

        '5' ->
            Just 5

        '6' ->
            Just 6

        '7' ->
            Just 7

        '8' ->
            Just 8

        '9' ->
            Just 9

        'a' ->
            Just 10

        'A' ->
            Just 10

        'b' ->
            Just 11

        'B' ->
            Just 11

        'c' ->
            Just 12

        'C' ->
            Just 12

        'd' ->
            Just 13

        'D' ->
            Just 13

        'e' ->
            Just 14

        'E' ->
            Just 14

        'f' ->
            Just 15

        'F' ->
            Just 15

        _ ->
            Nothing
