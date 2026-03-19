module Component.Dropdown exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { trigger : Html msg, items : List (Html msg) } -> Html msg
view config =
    Html.details
        [ Attr.class "relative inline-block" ]
        [ Html.summary
            [ Attr.class "list-none cursor-pointer focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 rounded"
            , Attr.attribute "aria-haspopup" "menu"
            ]
            [ config.trigger ]
        , Html.div
            [ Attr.class "absolute right-0 z-20 mt-1 min-w-40 rounded-lg border border-border-default bg-white shadow-md py-1"
            , Attr.attribute "role" "menu"
            ]
            (List.map viewItem config.items)
        ]


viewItem : Html msg -> Html msg
viewItem item =
    Html.div
        [ Attr.class "[&>*]:block [&>*]:w-full [&>*]:px-4 [&>*]:py-2 [&>*]:text-sm [&>*]:text-text-primary [&>*]:hover:bg-bg-subtle [&>*]:transition-colors [&>*]:text-left"
        , Attr.attribute "role" "menuitem"
        ]
        [ item ]
