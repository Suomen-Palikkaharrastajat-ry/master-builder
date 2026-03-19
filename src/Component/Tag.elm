module Component.Tag exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view : { label : String, onRemove : Maybe msg } -> Html msg
view config =
    Html.span
        [ Attr.class "inline-flex items-center gap-1 rounded-full bg-bg-subtle border border-border-default px-3 py-0.5 text-sm font-medium text-text-primary" ]
        [ Html.text config.label
        , case config.onRemove of
            Just onRemove ->
                Html.button
                    [ Events.onClick onRemove
                    , Attr.attribute "aria-label" ("Poista " ++ config.label)
                    , Attr.class "inline-flex items-center justify-center ml-1 w-4 h-4 rounded-full text-text-muted hover:text-text-primary hover:bg-gray-200 transition-colors focus-visible:ring-2 focus-visible:ring-brand cursor-pointer"
                    ]
                    [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text "✕" ] ]

            Nothing ->
                Html.text ""
        ]
