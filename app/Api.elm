module Api exposing (routes)

{-| elm-pages API route definitions.
-}

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import Color
import Config
import DesignTokens.Metadata as MetadataTokens
import FatalError exposing (FatalError)
import Html exposing (Html)
import LanguageTag
import LanguageTag.Language
import LanguageTag.Region
import MimeType
import Pages.Manifest as Manifest
import Pages.Url
import Route exposing (Route)


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ Manifest.generator MetadataTokens.canonicalUrl manifestConfig
    ]


manifestConfig : BackendTask FatalError Manifest.Config
manifestConfig =
    Config.task
        |> BackendTask.map
            (\config ->
                let
                    subtags =
                        LanguageTag.emptySubtags
                in
                Manifest.init
                    { name = config.site.title
                    , description = config.site.description
                    , startUrl = Route.Index |> Route.toPath
                    , icons =
                        [ { src = Pages.Url.external "/icon-192.png"
                          , sizes = [ ( 192, 192 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeAny ]
                          }
                        , { src = Pages.Url.external "/icon-512.png"
                          , sizes = [ ( 512, 512 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeAny ]
                          }
                        , { src = Pages.Url.external "/icon-maskable.png"
                          , sizes = [ ( 512, 512 ) ]
                          , mimeType = Just MimeType.Png
                          , purposes = [ Manifest.IconPurposeMaskable ]
                          }
                        ]
                    }
                    |> Manifest.withShortName MetadataTokens.siteShortName
                    |> Manifest.withDisplayMode Manifest.Standalone
                    |> Manifest.withBackgroundColor (Color.rgb255 255 255 255)
                    |> Manifest.withThemeColor (Color.rgb255 5 19 29)
                    |> Manifest.withLang
                        (LanguageTag.Language.fi
                            |> LanguageTag.build
                                { subtags | region = Just LanguageTag.Region.fi }
                        )
            )
