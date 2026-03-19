module Component.Spinner exposing (Size(..), view)

import Html exposing (Html)
import Html.Attributes as Attr


type Size
    = Small
    | Medium
    | Large


view : { size : Size, label : String } -> Html msg
view config =
    Html.span
        [ Attr.attribute "role" "status"
        , Attr.class "inline-flex items-center gap-2"
        ]
        [ Html.span
            [ Attr.class ("animate-spin rounded-full border-2 border-gray-200 border-t-brand " ++ sizeClass config.size) ]
            []
        , Html.span
            [ Attr.class "sr-only" ]
            [ Html.text config.label ]
        ]


sizeClass : Size -> String
sizeClass size =
    case size of
        Small ->
            "h-4 w-4"

        Medium ->
            "h-6 w-6"

        Large ->
            "h-8 w-8"
