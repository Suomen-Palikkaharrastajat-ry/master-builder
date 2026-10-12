module Component.Footer.Family exposing (view)

{-| The one footer shared by every site in the Palikkaharrastajat repository family.

Sites render their footer with `view` instead of assembling `Component.Footer`
themselves, so the logo, layout and typography cannot drift between sites. The
content comes from the site's resolved configuration: the family defaults in
`packages/site-config/family.toml`, overridden by the site's own `[footer]`.

@docs view

-}

import Component.Footer as Footer
import Html exposing (Html)
import Html.Attributes as Attr
import SiteSettings
import Tailwind as Tw exposing (classes)
import TailwindExtra as TwEx


{-| The family footer.

  - `topMargin` — `True` for document-style pages (`mt-16`), `False` for app
    shells that push the footer down themselves (`mt-auto`).
  - `extra` — site-specific lines shown under the disclaimer.

-}
view :
    { topMargin : Bool
    , extra : List (Html msg)
    }
    -> SiteSettings.Footer
    -> Html msg
view options footer =
    Footer.viewWith options
        { logo =
            Just
                (Html.img
                    [ Attr.src footer.footerLogo
                    , Attr.alt ""
                    , Attr.attribute "aria-hidden" "true"
                    , classes [ TwEx.h_35, TwEx.w_35, Tw.shrink_0 ]
                    ]
                    []
                )
        , siteLabel = Just footer.siteLabel
        , links = footer.links
        , groups = []
        , copyright = footer.copyright
        , disclaimer = Just footer.disclaimer
        }
