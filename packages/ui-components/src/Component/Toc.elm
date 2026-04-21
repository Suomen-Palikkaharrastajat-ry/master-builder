module Component.Toc exposing (TocChildItem, TocItem, view)

{-| Table of contents component — renders a card grid of child page links,
optionally showing nested child links within each card.
-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


type alias TocChildItem =
    { title : String
    , href : String
    }


type alias TocItem =
    { title : String
    , href : String
    , description : String
    , children : List TocChildItem
    }


view : Maybe String -> List TocItem -> Html msg
view extraClass items =
    if List.isEmpty items then
        Html.text ""

    else
        Html.div
            [ classes
                ([ TwEx.not_prose
                 , Tw.grid
                 , Tw.grid_cols_1
                 , Bp.sm [ Tw.grid_cols_2 ]
                 , Tw.gap Th.s4
                 , Tw.my Th.s6
                 ]
                    ++ (extraClass
                            |> Maybe.map (List.singleton << Tw.raw)
                            |> Maybe.withDefault []
                       )
                )
            ]
            (List.map viewItem items)


viewItem : TocItem -> Html msg
viewItem item =
    Html.div
        [ classes
            [ Tw.rounded_lg
            , Tw.border
            , Tw.border_simple TC.borderDefault
            , Tw.p Th.s4
            , Tw.bg_simple Th.white
            ]
        ]
        [ Html.a
            [ Attr.href item.href
            , classes
                [ Tw.block
                , Tw.no_underline
                , Bp.hover [ Tw.text_simple TC.brand ]
                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                , Bp.focus [ Tw.outline_none ]
                , Bp.focus_visible [ Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                ]
            ]
            [ Html.h3
                [ classes [ Tw.type_h4, Tw.text_simple TC.brand, Tw.mb Th.s1, Tw.mt Th.s0 ] ]
                [ Html.text item.title ]
            , if String.isEmpty item.description then
                Html.text ""

              else
                Html.p
                    [ classes [ Tw.type_caption, Tw.text_simple TC.textMuted, Tw.m Th.s0 ] ]
                    [ Html.text item.description ]
            ]
        , if List.isEmpty item.children then
            Html.text ""

          else
            Html.ul
                [ classes
                    [ Tw.mt Th.s3
                    , Tw.pt Th.s3
                    , Tw.border_t
                    , Tw.border_simple TC.borderDefault
                    , Tw.list_none
                    , Tw.m Th.s0
                    , Tw.p Th.s0
                    , TwEx.space_y Th.s1
                    ]
                ]
                (List.map viewChildItem item.children)
        ]


viewChildItem : TocChildItem -> Html msg
viewChildItem child =
    Html.li []
        [ Html.a
            [ Attr.href child.href
            , classes
                [ Tw.flex
                , Tw.items_center
                , Tw.gap Th.s1_dot_5
                , Tw.no_underline
                , Tw.type_caption
                , Tw.text_simple TC.textMuted
                , Bp.hover [ Tw.text_simple TC.brand ]
                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                ]
            ]
            [ Html.span [ classes [ Tw.text_simple TC.brand ] ] [ Html.text "→" ]
            , Html.text child.title
            ]
        ]
