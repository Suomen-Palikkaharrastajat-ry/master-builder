module Component.Placeholder exposing (view, viewLine, viewBlock)

import Html exposing (Html)
import Html.Attributes as Attr


view : List (Html msg) -> Html msg
view items =
    Html.div
        [ Attr.class "space-y-3 animate-pulse"
        , Attr.attribute "aria-hidden" "true"
        , Attr.attribute "role" "status"
        , Attr.attribute "aria-label" "Ladataan..."
        ]
        items


viewLine : { width : String } -> Html msg
viewLine config =
    Html.div
        [ Attr.class ("h-4 rounded bg-gray-200 " ++ config.width) ]
        []


viewBlock : { height : String } -> Html msg
viewBlock config =
    Html.div
        [ Attr.class ("w-full rounded bg-gray-200 " ++ config.height) ]
        []
