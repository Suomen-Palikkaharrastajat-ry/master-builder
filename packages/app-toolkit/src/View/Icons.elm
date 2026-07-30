module View.Icons exposing (featherIcon)

{-| Helpers for rendering Feather icons at a given size.
-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes


{-| Feather icons are decorative here: every call site pairs the glyph with a
visible label or an `aria-label` on the surrounding control. Hiding the `<svg>`
from assistive technology keeps it from being announced twice (or, worse,
announced as an unlabelled graphic). `focusable="false"` keeps legacy Edge/IE
from putting the `<svg>` itself into the tab order.
-}
featherIcon : FeatherIcons.Icon -> Float -> Html msg
featherIcon icon size =
    icon
        |> FeatherIcons.withSize size
        |> FeatherIcons.toHtml
            [ Html.Attributes.attribute "aria-hidden" "true"
            , Html.Attributes.attribute "focusable" "false"
            ]
