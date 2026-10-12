module Component.Footer.Family exposing
    ( view, viewWith
    , links, linksExcept, siteLabel, copyright, disclaimer, logo
    )

{-| The one footer shared by every site in the Palikkaharrastajat repository family.

Sites render their footer with `view` (canonical content) or `viewWith`
(configurable content) instead of assembling `Component.Footer` themselves, so
the logo, layout and typography cannot drift between sites.

@docs view, viewWith
@docs links, linksExcept, siteLabel, copyright, disclaimer, logo

-}

import Component.Footer as Footer
import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import TailwindExtra as TwEx


{-| The family footer with the canonical content.

  - `currentSite` — this site's own URL exactly as it appears in `links` (e.g.
    `"https://kartta.palikkaharrastajat.fi"`); the link to it is left out.
  - `year` — copyright year.
  - `topMargin` — `True` for document-style pages (`mt-16`), `False` for app
    shells that push the footer down themselves (`mt-auto`).
  - `extra` — site-specific lines shown under the disclaimer.

-}
view :
    { currentSite : String
    , year : Int
    , topMargin : Bool
    , extra : List (Html msg)
    }
    -> Html msg
view config =
    viewWith
        { topMargin = config.topMargin
        , extra = config.extra
        , siteLabel = siteLabel
        , links = linksExcept config.currentSite
        , copyright = copyright config.year
        , disclaimer = disclaimer
        }


{-| The family footer with configurable content: same logo, layout and
typography as `view`, but the site supplies its own label, links, copyright and
disclaimer (a translated site, or one whose content comes from configuration).
Start from `linksExcept`, `siteLabel`, `copyright` and `disclaimer` and override
only what differs.
-}
viewWith :
    { topMargin : Bool
    , extra : List (Html msg)
    , siteLabel : String
    , links : List { label : String, href : String }
    , copyright : String
    , disclaimer : List String
    }
    -> Html msg
viewWith config =
    Footer.viewWith
        { topMargin = config.topMargin
        , extra = config.extra
        }
        { logo = Just logo
        , siteLabel = Just config.siteLabel
        , links = config.links
        , groups = []
        , copyright = config.copyright
        , disclaimer = Just config.disclaimer
        }


{-| Canonical link set for the Suomen Palikkaharrastajat ry family of sites, in
canonical order. Changing this list changes every site's footer.
-}
links : List { label : String, href : String }
links =
    [ { label = "Kotisivut", href = "https://palikkaharrastajat.fi" }
    , { label = "Palikkakalenteri", href = "https://kalenteri.palikkaharrastajat.fi" }
    , { label = "Palikkakartta", href = "https://kartta.palikkaharrastajat.fi" }
    , { label = "Palikkalinkit", href = "https://linkit.palikkaharrastajat.fi" }
    , { label = "Jäsenfoorumi", href = "https://forum.palikkaharrastajat.fi" }
    , { label = "Jäsenkortti", href = "https://kortti.palikkaharrastajat.fi" }
    , { label = "Jäsenmaksu", href = "https://maksut.palikkaharrastajat.fi" }
    , { label = "Tietosuoja", href = "https://palikkaharrastajat.fi/tietosuoja" }
    ]


{-| `links` without the link to the given site URL (exact `href` match).
-}
linksExcept : String -> List { label : String, href : String }
linksExcept currentSite =
    List.filter (\link -> link.href /= currentSite) links


{-| Canonical label shown above the link list.
-}
siteLabel : String
siteLabel =
    "Palikkaharrastajat"


{-| Canonical copyright string given a year.
-}
copyright : Int -> String
copyright year =
    "© " ++ String.fromInt year ++ " Suomen Palikkaharrastajat ry"


{-| Canonical LEGO trademark disclaimer lines.
-}
disclaimer : List String
disclaimer =
    [ "LEGO® on LEGO Groupin rekisteröity tavaramerkki."
    , "LEGO Group ei ylläpidä tai tue tätä itsenäistä sivustoa."
    ]


{-| Canonical square footer logo image element.
-}
logo : Html msg
logo =
    Html.img
        [ Attr.src "/logo/square/svg/square-smile-full-dark-bold.svg"
        , Attr.alt ""
        , Attr.attribute "aria-hidden" "true"
        , classes [ TwEx.h_35, TwEx.w_35, Tw.shrink_0 ]
        ]
        []
