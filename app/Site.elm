module Site exposing (config)

{-| elm-pages site configuration (metadata, manifest, head tags).
-}

import BackendTask exposing (BackendTask)
import Config
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

                    metadata =
                        config_.metadata

                    icons =
                        config_.icons

                    pwa =
                        config_.pwa

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
                , Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
                , Head.metaProperty "og:locale" (Head.raw metadata.locale)
                , Head.metaName "theme-color" (Head.raw metadata.themeColor)
                , Head.metaName "color-scheme" (Head.raw metadata.colorScheme)
                , Head.metaName "format-detection" (Head.raw metadata.formatDetection)
                , Head.metaName "application-name" (Head.raw pwa.applicationName)
                , Head.metaName "apple-mobile-web-app-capable"
                    (Head.raw
                        (if pwa.appleMobileWebAppCapable then
                            "yes"

                         else
                            "no"
                        )
                    )
                , Head.metaName "apple-mobile-web-app-status-bar-style" (Head.raw pwa.appleMobileWebAppStatusBarStyle)
                , Head.metaName "apple-mobile-web-app-title" (Head.raw pwa.appleMobileWebAppTitle)
                , Head.metaName "mobile-web-app-capable"
                    (Head.raw
                        (if pwa.mobileWebAppCapable then
                            "yes"

                         else
                            "no"
                        )
                    )
                , Head.sitemapLink "/sitemap.xml"
                , Head.nonLoadingNode "link"
                    [ ( "rel", Head.raw "icon" )
                    , ( "href", Head.raw icons.faviconIco )
                    , ( "sizes", Head.raw "any" )
                    ]
                , Head.nonLoadingNode "link"
                    [ ( "rel", Head.raw "icon" )
                    , ( "href", Head.raw icons.faviconSvg )
                    , ( "type", Head.raw "image/svg+xml" )
                    , ( "sizes", Head.raw "any" )
                    ]
                , Head.icon [ ( 16, 16 ) ] MimeType.Png (iconUrl icons.favicon16)
                , Head.icon [ ( 32, 32 ) ] MimeType.Png (iconUrl icons.favicon32)
                , Head.icon [ ( 48, 48 ) ] MimeType.Png (iconUrl icons.favicon48)
                , Head.icon [ ( 64, 64 ) ] MimeType.Png (iconUrl icons.favicon64)
                , Head.appleTouchIcon (Just 120) (iconUrl icons.appleTouchIcon120)
                , Head.appleTouchIcon (Just 152) (iconUrl icons.appleTouchIcon152)
                , Head.appleTouchIcon (Just 167) (iconUrl icons.appleTouchIcon167)
                , Head.appleTouchIcon (Just icons.appleTouchIconSize) (iconUrl icons.appleTouchIcon)
                , Head.icon [ ( 192, 192 ) ] MimeType.Png (iconUrl icons.androidChrome192)
                , Head.icon [ ( 512, 512 ) ] MimeType.Png (iconUrl icons.androidChrome512)
                , Head.appleTouchIcon (Just 192) (iconUrl icons.appleTouchIcon192)
                , Head.appleTouchIcon (Just 512) (iconUrl icons.appleTouchIcon512)
                , Head.metaName "build-sha" (Head.raw meta.buildSha)
                , Head.metaName "build-timestamp" (Head.raw meta.buildTimestamp)
                , Head.metaName "build-run-id" (Head.raw meta.runId)
                ]
                    ++ Metadata.maybeMetaName "author" metadata.author
                    ++ Metadata.maybeMetaName "twitter:site" metadata.twitterSite
                    ++ Metadata.websiteStructuredData
                        { name = config_.site.title
                        , description = config_.site.description
                        , logoPath = config_.footer.footerLogo
                        , url = siteUrl
                        }
            )
