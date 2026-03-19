module Component.Breadcrumb exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : List { label : String, href : Maybe String } -> Html msg
view items =
    Html.nav [ Attr.attribute "aria-label" "Breadcrumb" ]
        [ Html.ol
            [ Attr.class "flex items-center gap-2 text-sm text-text-muted" ]
            (List.indexedMap (viewItem (List.length items)) items)
        ]


viewItem : Int -> Int -> { label : String, href : Maybe String } -> Html msg
viewItem total index item =
    let
        isLast =
            index == total - 1
    in
    Html.li [ Attr.class "flex items-center gap-2" ]
        ([ case item.href of
            Just href ->
                Html.a
                    [ Attr.href href
                    , Attr.class "hover:text-text-primary transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 rounded"
                    ]
                    [ Html.text item.label ]

            Nothing ->
                Html.span
                    (if isLast then
                        [ Attr.class "text-text-primary font-medium"
                        , Attr.attribute "aria-current" "page"
                        ]

                     else
                        []
                    )
                    [ Html.text item.label ]
         ]
            ++ (if isLast then
                    []

                else
                    [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text "/" ] ]
               )
        )
