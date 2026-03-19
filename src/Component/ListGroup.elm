module Component.ListGroup exposing (Item, view)

import Html exposing (Html)
import Html.Attributes as Attr


type alias Item msg =
    { content : Html msg
    , active : Bool
    , badge : Maybe (Html msg)
    }


view : List (Item msg) -> Html msg
view items =
    Html.ul
        [ Attr.class "divide-y divide-border-default border border-border-default rounded-lg overflow-hidden" ]
        (List.map viewItem items)


viewItem : Item msg -> Html msg
viewItem item =
    Html.li
        [ Attr.class
            ("flex items-center justify-between px-4 py-3 text-sm "
                ++ (if item.active then
                        "bg-brand text-white"

                    else
                        "bg-white text-text-primary hover:bg-bg-subtle"
                   )
            )
        ]
        [ item.content
        , case item.badge of
            Just badge ->
                badge

            Nothing ->
                Html.text ""
        ]
