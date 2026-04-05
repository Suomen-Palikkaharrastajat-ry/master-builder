module Config exposing (BrandingConfig, Config, FooterConfig, FooterLink, NavbarConfig, SiteConfig, task)

{-| Site-wide configuration loaded from content/config.toml at build time.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Config =
    { site : SiteConfig
    , branding : BrandingConfig
    , navbar : NavbarConfig
    , footer : FooterConfig
    }


type alias SiteConfig =
    { title : String
    , description : String
    , url : String
    }


type alias BrandingConfig =
    { logoLight : String
    , logoDark : String
    , logoAlt : String
    }


type alias NavbarConfig =
    { sticky : Bool
    }


type alias FooterConfig =
    { links : List FooterLink
    , copyright : String
    , disclaimer : String
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
    Decode.map4 Config
        (Decode.field "site" siteDecoder)
        (Decode.field "branding" brandingDecoder)
        (Decode.field "navbar" navbarDecoder)
        (Decode.field "footer" footerDecoder)


siteDecoder : Decoder SiteConfig
siteDecoder =
    Decode.map3 SiteConfig
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "url" Decode.string)


brandingDecoder : Decoder BrandingConfig
brandingDecoder =
    Decode.map3 BrandingConfig
        (Decode.field "logo_light" Decode.string)
        (Decode.field "logo_dark" Decode.string)
        (Decode.field "logo_alt" Decode.string)


navbarDecoder : Decoder NavbarConfig
navbarDecoder =
    Decode.map NavbarConfig
        (Decode.field "sticky" Decode.bool)


footerDecoder : Decoder FooterConfig
footerDecoder =
    Decode.map5 FooterConfig
        (Decode.field "links" (Decode.list footerLinkDecoder))
        (Decode.field "copyright" Decode.string)
        (Decode.field "disclaimer" Decode.string)
        (Decode.field "logo" Decode.string)
        (Decode.field "site_label" Decode.string)


footerLinkDecoder : Decoder FooterLink
footerLinkDecoder =
    Decode.map2 FooterLink
        (Decode.field "label" Decode.string)
        (Decode.field "href" Decode.string)
