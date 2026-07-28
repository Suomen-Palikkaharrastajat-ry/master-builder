module View.MapWidget exposing (view)

{-| A map container widget.

The actual map (Leaflet, MapLibre, ...) is initialized via a port after this
element is rendered; this module only provides the container element.

-}

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)


view : { containerId : String } -> Html msg
view config =
    div
        [ id config.containerId
        , style "height" "400px"
        , style "width" "100%"
        ]
        []
