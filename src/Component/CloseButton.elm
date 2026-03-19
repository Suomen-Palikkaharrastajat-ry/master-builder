module Component.CloseButton exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view : { onClick : msg, label : String } -> Html msg
view config =
    Html.button
        [ Events.onClick config.onClick
        , Attr.attribute "aria-label" config.label
        , Attr.class "inline-flex items-center justify-center w-8 h-8 rounded text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 cursor-pointer"
        ]
        [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text "✕" ] ]
