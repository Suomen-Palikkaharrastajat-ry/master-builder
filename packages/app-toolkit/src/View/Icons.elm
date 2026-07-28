module View.Icons exposing (featherIcon)

{-| Helpers for rendering Feather icons at a given size.
-}

import FeatherIcons
import Html exposing (Html)


featherIcon : FeatherIcons.Icon -> Float -> Html msg
featherIcon icon size =
    icon
        |> FeatherIcons.withSize size
        |> FeatherIcons.toHtml []
