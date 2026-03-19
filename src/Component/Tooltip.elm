module Component.Tooltip exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { content : String, children : List (Html msg) } -> Html msg
view config =
    Html.span
        [ Attr.class "relative inline-flex group" ]
        (config.children
            ++ [ Html.span
                    [ Attr.class "pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-2 z-30 hidden group-hover:block group-focus-within:block"
                    , Attr.attribute "role" "tooltip"
                    ]
                    [ Html.span
                        [ Attr.class "block whitespace-nowrap rounded bg-brand text-white text-xs font-medium px-2 py-1 shadow" ]
                        [ Html.text config.content ]
                    , Html.span
                        [ Attr.class "block mx-auto w-2 h-2 -mt-1 rotate-45 bg-brand"
                        , Attr.attribute "aria-hidden" "true"
                        ]
                        []
                    ]
               ]
        )
