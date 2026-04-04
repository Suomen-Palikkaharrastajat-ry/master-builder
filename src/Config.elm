module Config exposing (BrandingConfig, Config, FooterConfig, FooterLink, SiteConfig, task)

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
    , footerLogo : String
    }


type alias FooterConfig =
    { links : List FooterLink
    , copyright : String
    , disclaimer : String
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
    Decode.map3 Config
        (Decode.field "site" siteDecoder)
        (Decode.field "branding" brandingDecoder)
        (Decode.field "footer" footerDecoder)


siteDecoder : Decoder SiteConfig
siteDecoder =
    Decode.map3 SiteConfig
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "url" Decode.string)


brandingDecoder : Decoder BrandingConfig
brandingDecoder =
    Decode.map4 BrandingConfig
        (Decode.field "logo_light" Decode.string)
        (Decode.field "logo_dark" Decode.string)
        (Decode.field "logo_alt" Decode.string)
        (Decode.field "footer_logo" Decode.string)


footerDecoder : Decoder FooterConfig
footerDecoder =
    Decode.map3 FooterConfig
        (Decode.field "links" (Decode.list footerLinkDecoder))
        (Decode.field "copyright" Decode.string)
        (Decode.field "disclaimer" Decode.string)


footerLinkDecoder : Decoder FooterLink
footerLinkDecoder =
    Decode.map2 FooterLink
        (Decode.field "label" Decode.string)
        (Decode.field "href" Decode.string)
