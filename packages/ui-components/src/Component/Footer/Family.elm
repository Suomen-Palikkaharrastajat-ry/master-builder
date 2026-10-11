module Component.Footer.Family exposing (links, copyright, disclaimer, logo)

{-| Canonical footer data for the Palikkaharrastajat repository family.

@docs links, copyright, disclaimer, logo

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import TailwindExtra as TwEx


{-| Canonical link set for the Suomen Palikkaharrastajat ry family of sites.
Apps may filter out their own URL if desired.
-}
links : List { label : String, href : String }
links =
    [ { label = "Kotisivut", href = "https://palikkaharrastajat.fi" }
    , { label = "Palikkakalenteri", href = "https://kalenteri.palikkaharrastajat.fi" }
    , { label = "Palikkakartta", href = "https://kartta.palikkaharrastajat.fi" }
    , { label = "Palikkaplaneetta", href = "https://planeetta.palikkaharrastajat.fi" }
    , { label = "Palikkalinkit", href = "https://linkit.palikkaharrastajat.fi" }
    , { label = "Jäsenfoorumi", href = "https://forum.palikkaharrastajat.fi" }
    , { label = "Jäsenkortti", href = "https://kortti.palikkaharrastajat.fi" }
    , { label = "Jäsenmaksu", href = "https://maksut.palikkaharrastajat.fi" }
    ]


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
