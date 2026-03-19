module Component.Collapse exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { summary : Html msg, body : List (Html msg), open : Bool } -> Html msg
view config =
    Html.details
        ([ Attr.class "border border-border-default rounded-lg overflow-hidden" ]
            ++ (if config.open then
                    [ Attr.attribute "open" "" ]

                else
                    []
               )
        )
        [ Html.summary
            [ Attr.class "flex cursor-pointer select-none items-center justify-between px-6 py-4 font-semibold text-text-primary hover:bg-bg-subtle transition-colors [&::-webkit-details-marker]:hidden focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2" ]
            [ config.summary
            , Html.span
                [ Attr.class "ml-4 shrink-0 text-text-muted transition-transform duration-200 group-open:rotate-180"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Html.text "▾" ]
            ]
        , Html.div
            [ Attr.class "px-6 py-4 text-sm leading-7 text-text-muted border-t border-border-default" ]
            config.body
        ]
