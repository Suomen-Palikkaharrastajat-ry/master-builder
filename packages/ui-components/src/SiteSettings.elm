module SiteSettings exposing
    ( SiteSettings, Localized
    , Site, Metadata, Icons, Pwa, PwaIcons, Branding, Navbar, Admin, Footer, Link
    , decoder, localizedDecoder, forLang, pickLang, appDecoder, placeholder
    )

{-| A site's configuration, as resolved from its `config.toml` and the family
defaults by `packages/site-config/site-config.mjs`.

Every type here must stay serializable by elm-pages (no `Json.Decode.Value`,
no functions): the hub ships its configuration to the browser as page data.

The resolver produces one complete configuration per language, so nothing here
has a fallback: a missing value is a build error there, not a default here.

@docs SiteSettings, Localized
@docs Site, Metadata, Icons, Pwa, PwaIcons, Branding, Navbar, Admin, Footer, Link
@docs decoder, localizedDecoder, forLang, pickLang, appDecoder, placeholder

-}

import Json.Decode as Decode exposing (Decoder)
import Lang exposing (Lang)


{-| The configurations of every language a site declares.
-}
type alias Localized =
    { default : Lang
    , languages : List Lang
    , configs : List ( Lang, SiteSettings )
    }


{-| A site's configuration in one language.

The free-form `[app]` table is not part of it: each app decodes its own
settings with `appDecoder`.

-}
type alias SiteSettings =
    { lang : Lang
    , site : Site
    , metadata : Metadata
    , icons : Icons
    , pwa : Pwa
    , branding : Branding
    , navbar : Navbar
    , admin : Admin
    , footer : Footer
    }


{-| -}
type alias Site =
    { title : String
    , description : String
    , url : String
    }


{-| -}
type alias Metadata =
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


{-| -}
type alias Icons =
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


{-| -}
type alias Pwa =
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
    , icons : PwaIcons
    }


{-| -}
type alias PwaIcons =
    { icon192 : String
    , icon512 : String
    , maskableIcon : String
    }


{-| -}
type alias Branding =
    { logoLight : String
    , logoLightMobile : String
    , logoDark : String
    , logoDarkMobile : String
    , logoAlt : String
    , logoSquare : String
    }


{-| `variant` is `"standard"`, `"compact"` or `"app"`.
-}
type alias Navbar =
    { sticky : Bool
    , variant : String
    , showDesktopSearch : Bool
    , links : List Link
    }


{-| -}
type alias Admin =
    { enabled : Bool
    , path : String
    , contentOwner : String
    , contentRepo : String
    , contentBranch : String
    , contentPath : String
    }


{-| -}
type alias Footer =
    { links : List Link
    , copyright : String
    , disclaimer : List String
    , footerLogo : String
    , siteLabel : String
    }


{-| -}
type alias Link =
    { label : String
    , href : String
    }


{-| The configuration for a language, or for the default language when the
site does not declare the requested one.
-}
forLang : Lang -> Localized -> Maybe SiteSettings
forLang lang localized =
    let
        find wanted =
            localized.configs
                |> List.filter (\( l, _ ) -> l == wanted)
                |> List.head
                |> Maybe.map Tuple.second
    in
    case find lang of
        Just config ->
            Just config

        Nothing ->
            find localized.default


{-| The language to show: the requested one when the site declares it,
otherwise the site's default.
-}
pickLang : Maybe String -> Localized -> Lang
pickLang requested localized =
    case requested |> Maybe.andThen Lang.fromString of
        Just lang ->
            if List.member lang localized.languages then
                lang

            else
                localized.default

        Nothing ->
            localized.default


{-| An empty configuration, for the branch an app must still handle when its
flags do not decode. The build validates `config.toml` and the decoder is
tested against the resolver, so this is not expected to be shown.
-}
placeholder : Lang -> SiteSettings
placeholder lang =
    { lang = lang
    , site = { title = "", description = "", url = "" }
    , metadata =
        { author = Nothing
        , locale = ""
        , robots = ""
        , themeColor = ""
        , colorScheme = ""
        , formatDetection = ""
        , defaultSocialImage = ""
        , defaultSocialImageAlt = ""
        , twitterCard = ""
        , twitterSite = Nothing
        }
    , icons =
        { faviconIco = ""
        , faviconSvg = ""
        , favicon16 = ""
        , favicon32 = ""
        , favicon48 = ""
        , favicon64 = ""
        , appleTouchIcon120 = ""
        , appleTouchIcon152 = ""
        , appleTouchIcon167 = ""
        , appleTouchIcon = ""
        , appleTouchIconSize = 180
        , appleTouchIcon192 = ""
        , appleTouchIcon512 = ""
        , androidChrome192 = ""
        , androidChrome512 = ""
        }
    , pwa =
        { manifestPath = ""
        , applicationName = ""
        , shortName = ""
        , description = ""
        , startUrl = "/"
        , display = ""
        , backgroundColor = ""
        , themeColor = ""
        , mobileWebAppCapable = False
        , appleMobileWebAppCapable = False
        , appleMobileWebAppStatusBarStyle = ""
        , appleMobileWebAppTitle = ""
        , icons = { icon192 = "", icon512 = "", maskableIcon = "" }
        }
    , branding =
        { logoLight = ""
        , logoLightMobile = ""
        , logoDark = ""
        , logoDarkMobile = ""
        , logoAlt = ""
        , logoSquare = ""
        }
    , navbar = { sticky = True, variant = "app", showDesktopSearch = False, links = [] }
    , admin =
        { enabled = False
        , path = ""
        , contentOwner = ""
        , contentRepo = ""
        , contentBranch = ""
        , contentPath = ""
        }
    , footer = { links = [], copyright = "", disclaimer = [], footerLogo = "", siteLabel = "" }
    }


{-| Decodes the resolver's whole output.
-}
localizedDecoder : Decoder Localized
localizedDecoder =
    Decode.map3 Localized
        (Decode.field "default" langDecoder)
        (Decode.field "languages" (Decode.list langDecoder))
        (Decode.field "languages" (Decode.list Decode.string)
            |> Decode.andThen
                (\codes ->
                    codes
                        |> List.map
                            (\code ->
                                Decode.map2 Tuple.pair
                                    (Decode.succeed code |> Decode.andThen langFromCode)
                                    (Decode.at [ "configs", code ] decoder)
                            )
                        |> List.foldr (Decode.map2 (::)) (Decode.succeed [])
                )
        )


langDecoder : Decoder Lang
langDecoder =
    Decode.string |> Decode.andThen langFromCode


langFromCode : String -> Decoder Lang
langFromCode code =
    case Lang.fromString code of
        Just lang ->
            Decode.succeed lang

        Nothing ->
            Decode.fail ("Unsupported language: " ++ code)


{-| Decodes an app's own `[app]` settings for a language from the resolver's
whole output.
-}
appDecoder : Lang -> Decoder a -> Decoder a
appDecoder lang settingsDecoder =
    Decode.at [ "configs", Lang.toString lang, "app" ] settingsDecoder


{-| Decodes one language's resolved configuration.
-}
decoder : Decoder SiteSettings
decoder =
    Decode.succeed SiteSettings
        |> andMap (Decode.field "lang" langDecoder)
        |> andMap (Decode.field "site" siteDecoder)
        |> andMap (Decode.field "metadata" metadataDecoder)
        |> andMap (Decode.field "icons" iconsDecoder)
        |> andMap (Decode.field "pwa" pwaDecoder)
        |> andMap (Decode.field "branding" brandingDecoder)
        |> andMap (Decode.field "navbar" navbarDecoder)
        |> andMap (Decode.field "admin" adminDecoder)
        |> andMap (Decode.field "footer" footerDecoder)


siteDecoder : Decoder Site
siteDecoder =
    Decode.map3 Site
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "url" Decode.string)


metadataDecoder : Decoder Metadata
metadataDecoder =
    Decode.succeed Metadata
        |> andMap (Decode.maybe (Decode.field "author" Decode.string))
        |> andMap (Decode.field "locale" Decode.string)
        |> andMap (Decode.field "robots" Decode.string)
        |> andMap (Decode.field "theme_color" Decode.string)
        |> andMap (Decode.field "color_scheme" Decode.string)
        |> andMap (Decode.field "format_detection" Decode.string)
        |> andMap (Decode.field "default_social_image" Decode.string)
        |> andMap (Decode.field "default_social_image_alt" Decode.string)
        |> andMap (Decode.field "twitter_card" Decode.string)
        |> andMap (Decode.maybe (Decode.field "twitter_site" Decode.string))


iconsDecoder : Decoder Icons
iconsDecoder =
    Decode.succeed Icons
        |> andMap (Decode.field "favicon_ico" Decode.string)
        |> andMap (Decode.field "favicon_svg" Decode.string)
        |> andMap (Decode.field "favicon_16" Decode.string)
        |> andMap (Decode.field "favicon_32" Decode.string)
        |> andMap (Decode.field "favicon_48" Decode.string)
        |> andMap (Decode.field "favicon_64" Decode.string)
        |> andMap (Decode.field "apple_touch_icon_120" Decode.string)
        |> andMap (Decode.field "apple_touch_icon_152" Decode.string)
        |> andMap (Decode.field "apple_touch_icon_167" Decode.string)
        |> andMap (Decode.field "apple_touch_icon" Decode.string)
        |> andMap (Decode.field "apple_touch_icon_size" Decode.int)
        |> andMap (Decode.field "apple_touch_icon_192" Decode.string)
        |> andMap (Decode.field "apple_touch_icon_512" Decode.string)
        |> andMap (Decode.field "android_chrome_192" Decode.string)
        |> andMap (Decode.field "android_chrome_512" Decode.string)


pwaDecoder : Decoder Pwa
pwaDecoder =
    Decode.succeed Pwa
        |> andMap (Decode.field "manifest_path" Decode.string)
        |> andMap (Decode.field "application_name" Decode.string)
        |> andMap (Decode.field "short_name" Decode.string)
        |> andMap (Decode.field "description" Decode.string)
        |> andMap (Decode.field "start_url" Decode.string)
        |> andMap (Decode.field "display" Decode.string)
        |> andMap (Decode.field "background_color" Decode.string)
        |> andMap (Decode.field "theme_color" Decode.string)
        |> andMap (Decode.field "mobile_web_app_capable" Decode.bool)
        |> andMap (Decode.field "apple_mobile_web_app_capable" Decode.bool)
        |> andMap (Decode.field "apple_mobile_web_app_status_bar_style" Decode.string)
        |> andMap (Decode.field "apple_mobile_web_app_title" Decode.string)
        |> andMap (Decode.field "icons" pwaIconsDecoder)


pwaIconsDecoder : Decoder PwaIcons
pwaIconsDecoder =
    Decode.map3 PwaIcons
        (Decode.field "icon_192" Decode.string)
        (Decode.field "icon_512" Decode.string)
        (Decode.field "maskable_icon" Decode.string)


brandingDecoder : Decoder Branding
brandingDecoder =
    Decode.succeed Branding
        |> andMap (Decode.field "logo_light" Decode.string)
        |> andMap (Decode.oneOf [ Decode.field "logo_light_mobile" Decode.string, Decode.field "logo_light" Decode.string ])
        |> andMap (Decode.field "logo_dark" Decode.string)
        |> andMap (Decode.oneOf [ Decode.field "logo_dark_mobile" Decode.string, Decode.field "logo_dark" Decode.string ])
        |> andMap (Decode.field "logo_alt" Decode.string)
        |> andMap (Decode.field "logo_square" Decode.string)


navbarDecoder : Decoder Navbar
navbarDecoder =
    Decode.map4 Navbar
        (Decode.field "sticky" Decode.bool)
        (Decode.field "variant" Decode.string)
        (Decode.field "show_desktop_search" Decode.bool)
        (Decode.field "links" (Decode.list linkDecoder))


adminDecoder : Decoder Admin
adminDecoder =
    Decode.succeed Admin
        |> andMap (Decode.field "enabled" Decode.bool)
        |> andMap (Decode.field "path" Decode.string)
        |> andMap (Decode.field "content_owner" Decode.string)
        |> andMap (Decode.field "content_repo" Decode.string)
        |> andMap (Decode.field "content_branch" Decode.string)
        |> andMap (Decode.field "content_path" Decode.string)


footerDecoder : Decoder Footer
footerDecoder =
    Decode.map5 Footer
        (Decode.field "links" (Decode.list linkDecoder))
        (Decode.field "copyright" Decode.string)
        (Decode.field "disclaimer" (Decode.list Decode.string))
        (Decode.field "logo" Decode.string)
        (Decode.field "site_label" Decode.string)


linkDecoder : Decoder Link
linkDecoder =
    Decode.map2 Link
        (Decode.field "label" Decode.string)
        (Decode.field "href" Decode.string)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valueDecoder functionDecoder =
    Decode.map2 (\fn value -> fn value) functionDecoder valueDecoder
