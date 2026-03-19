module Component.Pagination exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view : { currentPage : Int, totalPages : Int, onPageClick : Int -> msg } -> Html msg
view config =
    Html.nav
        [ Attr.attribute "aria-label" "Sivutus"
        , Attr.class "flex items-center gap-1"
        ]
        (List.map (viewPage config) (List.range 1 config.totalPages))


viewPage : { currentPage : Int, totalPages : Int, onPageClick : Int -> msg } -> Int -> Html msg
viewPage config page =
    let
        isCurrent =
            page == config.currentPage
    in
    Html.button
        [ Events.onClick (config.onPageClick page)
        , Attr.attribute "aria-current"
            (if isCurrent then
                "page"

             else
                "false"
            )
        , Attr.class
            ("inline-flex items-center justify-center w-9 h-9 rounded text-sm font-medium transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 cursor-pointer "
                ++ (if isCurrent then
                        "bg-brand text-white"

                    else
                        "text-text-primary hover:bg-bg-subtle"
                   )
            )
        ]
        [ Html.text (String.fromInt page) ]
