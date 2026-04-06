module Site exposing (config)

{-| elm-pages site configuration (metadata, manifest, head tags).
-}

import BackendTask exposing (BackendTask)
import Config
import DesignTokens.Metadata as MetadataTokens
import FatalError exposing (FatalError)
import Head
import LanguageTag
import LanguageTag.Language
import LanguageTag.Region
import Metadata
import MimeType
import Pages.Url
import SiteConfig exposing (SiteConfig)
import SiteMeta


config : SiteConfig
config =
    { canonicalUrl = "https://palikkaharrastajat.fi"
    , head = head
    }


head : BackendTask FatalError (List Head.Tag)
head =
    BackendTask.map2 Tuple.pair Config.task SiteMeta.task
        |> BackendTask.map
            (\( config_, meta ) ->
                let
                    siteUrl =
                        config_.site.url

                    subtags =
                        LanguageTag.emptySubtags

                    rootLanguage =
                        LanguageTag.Language.fi
                            |> LanguageTag.build
                                { subtags
                                    | region = Just LanguageTag.Region.fi
                                }

                    iconUrl path =
                        Pages.Url.external path
                in
                [ Head.rootLanguage rootLanguage
                , Head.nonLoadingNode "meta" [ ( "charset", Head.raw "UTF-8" ) ]
                , Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
                , Head.metaName "robots" (Head.raw MetadataTokens.robots)
                , Head.metaName "author" (Head.raw MetadataTokens.author)
                , Head.metaName "theme-color" (Head.raw MetadataTokens.themeColor)
                , Head.metaName "color-scheme" (Head.raw MetadataTokens.colorScheme)
                , Head.metaName "format-detection" (Head.raw MetadataTokens.formatDetection)
                , Head.metaName "application-name" (Head.raw MetadataTokens.applicationName)
                , Head.metaName "apple-mobile-web-app-capable"
                    (Head.raw
                        (if MetadataTokens.appleMobileWebAppCapable then
                            "yes"

                         else
                            "no"
                        )
                    )
                , Head.metaName "apple-mobile-web-app-status-bar-style" (Head.raw MetadataTokens.appleMobileWebAppStatusBarStyle)
                , Head.metaName "apple-mobile-web-app-title" (Head.raw MetadataTokens.appleMobileWebAppTitle)
                , Head.metaName "mobile-web-app-capable"
                    (Head.raw
                        (if MetadataTokens.mobileWebAppCapable then
                            "yes"

                         else
                            "no"
                        )
                    )
                , Head.sitemapLink "/sitemap.xml"
                , Head.manifestLink MetadataTokens.manifestUrl
                , Head.nonLoadingNode "link"
                    [ ( "rel", Head.raw "icon" )
                    , ( "href", Head.raw "/favicon.ico" )
                    , ( "type", Head.raw "image/x-icon" )
                    ]
                , Head.nonLoadingNode "link"
                    [ ( "rel", Head.raw "icon" )
                    , ( "href", Head.raw "/favicon.svg" )
                    , ( "type", Head.raw "image/svg+xml" )
                    , ( "sizes", Head.raw "any" )
                    ]
                , Head.icon [ ( 16, 16 ) ] MimeType.Png (iconUrl "/favicon-16x16.png")
                , Head.icon [ ( 32, 32 ) ] MimeType.Png (iconUrl "/favicon-32x32.png")
                , Head.icon [ ( 48, 48 ) ] MimeType.Png (iconUrl "/favicon-48x48.png")
                , Head.icon [ ( 192, 192 ) ] MimeType.Png (iconUrl "/android-chrome-192x192.png")
                , Head.icon [ ( 512, 512 ) ] MimeType.Png (iconUrl "/android-chrome-512x512.png")
                , Head.appleTouchIcon (Just 180) (iconUrl "/apple-touch-icon.png")
                , Head.metaName "build-sha" (Head.raw meta.buildSha)
                , Head.metaName "build-timestamp" (Head.raw meta.buildTimestamp)
                , Head.metaName "build-run-id" (Head.raw meta.runId)
                ]
                    ++ Metadata.websiteStructuredData
                        { name = config_.site.title
                        , description = config_.site.description
                        , url = siteUrl
                        }
            )
