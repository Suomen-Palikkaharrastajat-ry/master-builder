module Component.Footer exposing (LinkGroup, view)

{-| Site footer component — dark brand-coloured background.

Supports two layout modes:

  - **Brand layout** — logo + flat link list on the left, copyright and
    optional disclaimer on the right. Activated when `logo` is `Just`.
  - **Groups layout** — each `LinkGroup` is rendered as a column with a
    heading and list of links, copyright at the bottom. Used when `logo`
    is `Nothing`.

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


type alias LinkGroup =
    { heading : String
    , links : List { label : String, href : String }
    }


view :
    { logo : Maybe (Html msg)
    , siteLabel : Maybe String
    , links : List { label : String, href : String }
    , groups : List LinkGroup
    , copyright : String
    , disclaimer : Maybe String
    }
    -> Html msg
view config =
    let
        useBrandLayout =
            case config.logo of
                Just _ ->
                    True

                Nothing ->
                    not (List.isEmpty config.links)
    in
    Html.footer
        [ classes [ Tw.bg_simple TC.brand, Tw.text_simple Th.white, Tw.mt Th.s16, Tw.py Th.s12, Tw.px Th.s4 ] ]
        [ Html.div
            [ classes [ TwEx.max_w_5xl, Tw.mx_auto ] ]
            (if useBrandLayout then
                [ viewBrandLayout config ]

             else
                viewGroupsLayout config
            )
        ]


viewBrandLayout :
    { a
        | logo : Maybe (Html msg)
        , siteLabel : Maybe String
        , links : List { label : String, href : String }
        , copyright : String
        , disclaimer : Maybe String
    }
    -> Html msg
viewBrandLayout config =
    Html.div
        [ classes [ Tw.grid, Tw.gap Th.s8, Bp.sm [ Tw.items_end, Tw.grid_cols_2 ] ] ]
        [ Html.div [ classes [ Tw.flex, Tw.items_start, Tw.gap Th.s4 ] ]
            (List.filterMap identity
                [ Maybe.map
                    (\logoHtml -> Html.div [ classes [ Tw.shrink_0 ] ] [ logoHtml ])
                    config.logo
                , Just
                    (Html.div [ classes [ TwEx.space_y Th.s4 ] ]
                        (List.filterMap identity
                            [ Maybe.map
                                (\label ->
                                    Html.p
                                        [ classes [ Tw.text_xs, Tw.font_semibold, TwEx.text_white_50, Tw.uppercase, Tw.tracking_wider ] ]
                                        [ Html.text label ]
                                )
                                config.siteLabel
                            , if List.isEmpty config.links then
                                Nothing

                              else
                                Just
                                    (Html.ul
                                        [ classes [ TwEx.space_y Th.s2, Tw.list_none, Tw.m Th.s0, Tw.p Th.s0, Tw.grid, Tw.grid_cols_2 ] ]
                                        (List.map viewFlatLink config.links)
                                    )
                            ]
                        )
                    )
                ]
            )
        , Html.div [ classes [ TwEx.space_y Th.s1, Tw.pl Th.s4, Bp.sm [ Tw.text_right ] ] ]
            [ Html.div [ classes [ TwEx.space_y Th.s1, Tw.text_xs, TwEx.text_white_50 ] ]
                (List.filterMap identity
                    [ Just (Html.p [] [ Html.text config.copyright ])
                    , Maybe.map (\d -> Html.p [] [ Html.text d ]) config.disclaimer
                    ]
                )
            ]
        ]


viewGroupsLayout :
    { a
        | groups : List LinkGroup
        , copyright : String
    }
    -> List (Html msg)
viewGroupsLayout config =
    [ Html.div
        [ classes [ Tw.grid, Tw.grid_cols_2, Tw.gap Th.s8, Bp.md [ Tw.grid_cols_4 ] ] ]
        (List.map viewGroup config.groups)
    , Html.div
        [ classes [ Tw.mt Th.s10, Tw.border_t, TwEx.border_white_10, Tw.pt Th.s8 ] ]
        [ Html.p
            [ classes [ Tw.type_caption, TwEx.text_white_50, Tw.text_center ] ]
            [ Html.text config.copyright ]
        ]
    ]


viewGroup : LinkGroup -> Html msg
viewGroup group =
    Html.div []
        [ Html.h3
            [ classes [ Tw.type_body_small, Tw.text_simple Th.white ] ]
            [ Html.text group.heading ]
        , Html.ul
            [ classes [ Tw.mt Th.s4, TwEx.space_y Th.s3 ] ]
            (List.map viewGroupLink group.links)
        ]


viewGroupLink : { label : String, href : String } -> Html msg
viewGroupLink link =
    Html.li []
        [ Html.a
            [ Attr.href link.href
            , classes
                [ Tw.type_caption
                , TwEx.text_white_60
                , Bp.hover [ Tw.text_simple Th.white ]
                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                ]
            ]
            [ Html.text link.label ]
        ]


viewFlatLink : { label : String, href : String } -> Html msg
viewFlatLink link =
    Html.li []
        [ Html.a
            [ Attr.href link.href
            , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple Th.white ], Tw.underline, Tw.transition_colors ]
            ]
            [ Html.text link.label ]
        ]
