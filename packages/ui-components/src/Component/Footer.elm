module Component.Footer exposing (LinkGroup, view, viewWith)

{-| Site footer component — dark brand-coloured background.

Supports two layout modes:

  - **Brand layout** — logo + flat link list on the left, copyright and
    optional disclaimer on the right. Activated when `logo` is `Just`.
  - **Groups layout** — each `LinkGroup` is rendered as a column with a
    heading and list of links, copyright at the bottom. Used when `logo`
    is `Nothing`.

@docs LinkGroup, view, viewWith

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


{-| Renders the site footer with custom topMargin and extra column content options.
-}
viewWith :
    { topMargin : Bool
    , extra : List (Html msg)
    }
    ->
        { logo : Maybe (Html msg)
        , siteLabel : Maybe String
        , links : List { label : String, href : String }
        , groups : List LinkGroup
        , copyright : String
        , disclaimer : Maybe (List String)
        }
    -> Html msg
viewWith options config =
    let
        useBrandLayout =
            case config.logo of
                Just _ ->
                    True

                Nothing ->
                    not (List.isEmpty config.links)

        marginClass =
            if options.topMargin then
                Tw.mt Th.s16

            else
                Tw.mt_auto
    in
    Html.footer
        [ classes [ Tw.bg_simple TC.brand, Tw.text_simple Th.white, marginClass, Tw.py Th.s12, Tw.px Th.s4 ] ]
        [ Html.div
            [ classes [ TwEx.max_w_5xl, Tw.mx_auto ] ]
            (if useBrandLayout then
                [ viewBrandLayout options.extra config ]

             else
                viewGroupsLayout config
            )
        ]


{-| Default footer view with top margin and no extra items.
-}
view :
    { logo : Maybe (Html msg)
    , siteLabel : Maybe String
    , links : List { label : String, href : String }
    , groups : List LinkGroup
    , copyright : String
    , disclaimer : Maybe (List String)
    }
    -> Html msg
view =
    viewWith { topMargin = True, extra = [] }


viewBrandLayout :
    List (Html msg)
    ->
        { a
            | logo : Maybe (Html msg)
            , siteLabel : Maybe String
            , links : List { label : String, href : String }
            , copyright : String
            , disclaimer : Maybe (List String)
        }
    -> Html msg
viewBrandLayout extra config =
    Html.div
        [ classes [ Tw.grid, Tw.gap Th.s8, Bp.sm [ Tw.items_end, Tw.grid_cols_5 ] ] ]
        [ Html.div [ classes [ Tw.flex, Tw.items_start, Tw.gap Th.s4, Bp.sm [ Tw.col_span_3 ] ] ]
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
                                        [ classes [ Tw.type_overline, TwEx.text_white_50 ] ]
                                        [ Html.text label ]
                                )
                                config.siteLabel
                            , if List.isEmpty config.links then
                                Nothing

                              else
                                Just
                                    (Html.ul
                                        [ classes [ Tw.list_none, Tw.m Th.s0, Tw.p Th.s0, Tw.grid, Tw.grid_cols_2, Tw.gap_x Th.s6, Tw.gap_y Th.s2 ] ]
                                        (List.map viewFlatLink config.links)
                                    )
                            ]
                        )
                    )
                ]
            )
        , Html.div [ classes [ TwEx.space_y Th.s1, Tw.pl Th.s4, Bp.sm [ Tw.text_right, Tw.col_span_2 ] ] ]
            [ Html.div [ classes [ TwEx.space_y Th.s1, Tw.type_caption, TwEx.text_white_50 ] ]
                (List.filterMap identity
                    (Just (Html.p [] [ Html.text config.copyright ])
                        :: (config.disclaimer
                                |> Maybe.withDefault []
                                |> List.map (\d -> Just (Html.p [] [ Html.text d ]))
                           )
                    )
                    ++ extra
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
            , classes [ Tw.type_body_small, TwEx.text_white_80, Bp.hover [ Tw.text_simple Th.white ], Tw.underline, Tw.transition_colors ]
            ]
            [ Html.text link.label ]
        ]
