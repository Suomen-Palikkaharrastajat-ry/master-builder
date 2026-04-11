module Config exposing
    ( AdminConfig
    , BrandingConfig
    , Config
    , FooterConfig
    , FooterLink
    , IconConfig
    , MetadataConfig
    , NavbarConfig
    , PwaConfig
    , PwaIconConfig
    , SiteConfig
    , task
    )

{-| Site-wide configuration loaded from content/config.toml at build time.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Config =
    { site : SiteConfig
    , metadata : MetadataConfig
    , icons : IconConfig
    , pwa : PwaConfig
    , branding : BrandingConfig
    , navbar : NavbarConfig
    , admin : AdminConfig
    , footer : FooterConfig
    }


type alias SiteConfig =
    { title : String
    , description : String
    , url : String
    }


type alias MetadataConfig =
    { author : Maybe String
    , locale : String
    , robots : String
    , themeColor : String
    , colorScheme : String
    , formatDetection : String
    , defaultSocialImage : String
    , defaultSocialImageAlt : String
    , twitterCard : String
    , twitterSite : Maybe String
    }


type alias IconConfig =
    { faviconIco : String
    , faviconSvg : String
    , favicon16 : String
    , favicon32 : String
    , favicon48 : String
    , favicon64 : String
    , appleTouchIcon120 : String
    , appleTouchIcon152 : String
    , appleTouchIcon167 : String
    , appleTouchIcon : String
    , appleTouchIconSize : Int
    , appleTouchIcon192 : String
    , appleTouchIcon512 : String
    , androidChrome192 : String
    , androidChrome512 : String
    }


type alias PwaConfig =
    { manifestPath : String
    , applicationName : String
    , shortName : String
    , description : String
    , startUrl : String
    , display : String
    , backgroundColor : String
    , themeColor : String
    , mobileWebAppCapable : Bool
    , appleMobileWebAppCapable : Bool
    , appleMobileWebAppStatusBarStyle : String
    , appleMobileWebAppTitle : String
    , icons : PwaIconConfig
    }


type alias PwaIconConfig =
    { icon192 : String
    , icon512 : String
    , maskableIcon : String
    }


type alias BrandingConfig =
    { logoLight : String
    , logoLightMobile : String
    , logoDark : String
    , logoDarkMobile : String
    , logoAlt : String
    , logoSquare : String
    }


type alias NavbarConfig =
    { sticky : Bool
    , variant : String
    }


type alias AdminConfig =
    { enabled : Bool
    , path : String
    , contentOwner : String
    , contentRepo : String
    , contentBranch : String
    , contentPath : String
    }


type alias FooterConfig =
    { links : List FooterLink
    , copyright : String
    , disclaimer : List String
    , footerLogo : String
    , siteLabel : String
    }


type alias FooterLink =
    { label : String
    , href : String
    }


task : BackendTask FatalError Config
task =
    BackendTask.Custom.run "readToml"
        (Encode.string "content/config.toml")
        decoder
        |> BackendTask.allowFatal


decoder : Decoder Config
decoder =
    Decode.map8 Config
        (Decode.field "site" siteDecoder)
        (Decode.oneOf [ Decode.field "metadata" metadataDecoder, Decode.succeed defaultMetadataConfig ])
        (Decode.oneOf [ Decode.field "icons" iconDecoder, Decode.succeed defaultIconConfig ])
        (Decode.oneOf [ Decode.field "pwa" pwaDecoder, Decode.succeed defaultPwaConfig ])
        (Decode.field "branding" brandingDecoder)
        (Decode.field "navbar" navbarDecoder)
        (Decode.oneOf [ Decode.field "admin" adminDecoder, Decode.succeed defaultAdminConfig ])
        (Decode.field "footer" footerDecoder)


siteDecoder : Decoder SiteConfig
siteDecoder =
    Decode.map3 SiteConfig
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "url" Decode.string)


metadataDecoder : Decoder MetadataConfig
metadataDecoder =
    Decode.succeed MetadataConfig
        |> andMap (optionalMaybeField "author" Decode.string)
        |> andMap (optionalField "locale" Decode.string "fi_FI")
        |> andMap (optionalField "robots" Decode.string "index, follow")
        |> andMap (optionalField "theme_color" Decode.string "#05131D")
        |> andMap (optionalField "color_scheme" Decode.string "light")
        |> andMap (optionalField "format_detection" Decode.string "telephone=no")
        |> andMap (optionalField "default_social_image" Decode.string "/og-image.png")
        |> andMap (optionalField "default_social_image_alt" Decode.string "Suomen Palikkaharrastajat ry")
        |> andMap (optionalField "twitter_card" Decode.string "summary_large_image")
        |> andMap (optionalMaybeField "twitter_site" Decode.string)


iconDecoder : Decoder IconConfig
iconDecoder =
    Decode.succeed IconConfig
        |> andMap (optionalField "favicon_ico" Decode.string "/favicon.ico")
        |> andMap (optionalField "favicon_svg" Decode.string "/favicon.svg")
        |> andMap (optionalField "favicon_16" Decode.string "/favicon-16x16.png")
        |> andMap (optionalField "favicon_32" Decode.string "/favicon-32x32.png")
        |> andMap (optionalField "favicon_48" Decode.string "/favicon-48x48.png")
        |> andMap (optionalField "favicon_64" Decode.string "/favicon-64.png")
        |> andMap (optionalField "apple_touch_icon_120" Decode.string "/apple-touch-icon-120.png")
        |> andMap (optionalField "apple_touch_icon_152" Decode.string "/apple-touch-icon-152.png")
        |> andMap (optionalField "apple_touch_icon_167" Decode.string "/apple-touch-icon-167.png")
        |> andMap (optionalField "apple_touch_icon" Decode.string "/apple-touch-icon.png")
        |> andMap (optionalField "apple_touch_icon_size" Decode.int 180)
        |> andMap (optionalField "apple_touch_icon_192" Decode.string "/apple-touch-icon-192.png")
        |> andMap (optionalField "apple_touch_icon_512" Decode.string "/apple-touch-icon-512.png")
        |> andMap (optionalField "android_chrome_192" Decode.string "/android-chrome-192x192.png")
        |> andMap (optionalField "android_chrome_512" Decode.string "/android-chrome-512x512.png")


pwaDecoder : Decoder PwaConfig
pwaDecoder =
    Decode.succeed PwaConfig
        |> andMap (optionalField "manifest_path" Decode.string "/site.webmanifest")
        |> andMap (optionalField "application_name" Decode.string "Suomen Palikkaharrastajat ry")
        |> andMap (optionalField "short_name" Decode.string "Palikat")
        |> andMap (optionalField "description" Decode.string "Suomen LEGO-harrastajien yhteisö")
        |> andMap (optionalField "start_url" Decode.string "/")
        |> andMap (optionalField "display" Decode.string "standalone")
        |> andMap (optionalField "background_color" Decode.string "#FFFFFF")
        |> andMap (optionalField "theme_color" Decode.string "#05131D")
        |> andMap (optionalField "mobile_web_app_capable" Decode.bool True)
        |> andMap (optionalField "apple_mobile_web_app_capable" Decode.bool True)
        |> andMap (optionalField "apple_mobile_web_app_status_bar_style" Decode.string "default")
        |> andMap (optionalField "apple_mobile_web_app_title" Decode.string "Palikkaharrastajat")
        |> andMap (Decode.oneOf [ Decode.field "icons" pwaIconDecoder, Decode.succeed defaultPwaIconConfig ])


pwaIconDecoder : Decoder PwaIconConfig
pwaIconDecoder =
    Decode.map3 PwaIconConfig
        (optionalField "icon_192" Decode.string "/icon-192.png")
        (optionalField "icon_512" Decode.string "/icon-512.png")
        (optionalField "maskable_icon" Decode.string "/icon-maskable.png")


brandingDecoder : Decoder BrandingConfig
brandingDecoder =
    Decode.succeed BrandingConfig
        |> andMap (Decode.field "logo_light" Decode.string)
        |> andMap (Decode.field "logo_light_mobile" Decode.string)
        |> andMap (Decode.field "logo_dark" Decode.string)
        |> andMap (Decode.field "logo_dark_mobile" Decode.string)
        |> andMap (Decode.field "logo_alt" Decode.string)
        |> andMap (optionalField "logo_square" Decode.string "/logo/square/svg/square-smile.svg")


navbarDecoder : Decoder NavbarConfig
navbarDecoder =
    Decode.succeed NavbarConfig
        |> andMap (Decode.field "sticky" Decode.bool)
        |> andMap (optionalField "variant" Decode.string "standard")


adminDecoder : Decoder AdminConfig
adminDecoder =
    Decode.succeed AdminConfig
        |> andMap (optionalField "enabled" Decode.bool False)
        |> andMap (optionalField "path" Decode.string "/admin/")
        |> andMap (optionalField "content_owner" Decode.string "")
        |> andMap (optionalField "content_repo" Decode.string "")
        |> andMap (optionalField "content_branch" Decode.string "main")
        |> andMap (optionalField "content_path" Decode.string "")


footerDecoder : Decoder FooterConfig
footerDecoder =
    Decode.map5 FooterConfig
        (Decode.field "links" (Decode.list footerLinkDecoder))
        (Decode.field "copyright" Decode.string)
        (optionalField "disclaimer" (Decode.list Decode.string) [])
        (Decode.field "logo" Decode.string)
        (Decode.field "site_label" Decode.string)


footerLinkDecoder : Decoder FooterLink
footerLinkDecoder =
    Decode.map2 FooterLink
        (Decode.field "label" Decode.string)
        (Decode.field "href" Decode.string)


optionalField : String -> Decoder a -> a -> Decoder a
optionalField fieldName fieldDecoder fallback =
    Decode.oneOf
        [ Decode.field fieldName fieldDecoder
        , Decode.succeed fallback
        ]


optionalMaybeField : String -> Decoder a -> Decoder (Maybe a)
optionalMaybeField fieldName fieldDecoder =
    Decode.maybe (Decode.field fieldName fieldDecoder)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valueDecoder functionDecoder =
    Decode.map2 (\fn value -> fn value) functionDecoder valueDecoder


defaultMetadataConfig : MetadataConfig
defaultMetadataConfig =
    { author = Nothing
    , locale = "fi_FI"
    , robots = "index, follow"
    , themeColor = "#05131D"
    , colorScheme = "light"
    , formatDetection = "telephone=no"
    , defaultSocialImage = "/og-image.png"
    , defaultSocialImageAlt = "Suomen Palikkaharrastajat ry"
    , twitterCard = "summary_large_image"
    , twitterSite = Nothing
    }


defaultIconConfig : IconConfig
defaultIconConfig =
    { faviconIco = "/favicon.ico"
    , faviconSvg = "/favicon.svg"
    , favicon16 = "/favicon-16x16.png"
    , favicon32 = "/favicon-32x32.png"
    , favicon48 = "/favicon-48x48.png"
    , favicon64 = "/favicon-64.png"
    , appleTouchIcon120 = "/apple-touch-icon-120.png"
    , appleTouchIcon152 = "/apple-touch-icon-152.png"
    , appleTouchIcon167 = "/apple-touch-icon-167.png"
    , appleTouchIcon = "/apple-touch-icon.png"
    , appleTouchIconSize = 180
    , appleTouchIcon192 = "/apple-touch-icon-192.png"
    , appleTouchIcon512 = "/apple-touch-icon-512.png"
    , androidChrome192 = "/android-chrome-192x192.png"
    , androidChrome512 = "/android-chrome-512x512.png"
    }


defaultPwaConfig : PwaConfig
defaultPwaConfig =
    { manifestPath = "/site.webmanifest"
    , applicationName = "Suomen Palikkaharrastajat ry"
    , shortName = "Palikat"
    , description = "Suomen LEGO-harrastajien yhteisö"
    , startUrl = "/"
    , display = "standalone"
    , backgroundColor = "#FFFFFF"
    , themeColor = "#05131D"
    , mobileWebAppCapable = True
    , appleMobileWebAppCapable = True
    , appleMobileWebAppStatusBarStyle = "default"
    , appleMobileWebAppTitle = "Palikkaharrastajat"
    , icons = defaultPwaIconConfig
    }


defaultPwaIconConfig : PwaIconConfig
defaultPwaIconConfig =
    { icon192 = "/icon-192.png"
    , icon512 = "/icon-512.png"
    , maskableIcon = "/icon-maskable.png"
    }


defaultAdminConfig : AdminConfig
defaultAdminConfig =
    { enabled = False
    , path = "/admin/"
    , contentOwner = ""
    , contentRepo = ""
    , contentBranch = "main"
    , contentPath = ""
    }
