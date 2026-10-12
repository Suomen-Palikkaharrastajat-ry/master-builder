module Component.FeedLinks exposing (Card, FeedGroup, view)

{-| Shared "subscribe / export" panel for calendar and map applications.

@docs Card, FeedGroup, view

-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Single export card linking to a file or calendar export.
-}
type alias Card =
    { icon : FeatherIcons.Icon
    , title : String
    , description : String
    , href : String
    }


{-| Column grouping feed export links (e.g. ATOM, RSS, JSON).
-}
type alias FeedGroup =
    { icon : FeatherIcons.Icon
    , title : String
    , description : String
    , links : List { label : String, href : String }
    }


{-| Renders the subscribe and export panel as an accessible section.
-}
view :
    { label : String
    , cards : List Card
    , feeds : Maybe FeedGroup
    , newTabHint : String
    }
    -> Html msg
view config =
    Html.section
        [ Attr.attribute "aria-label" config.label
        , classes
            [ Tw.mt_auto
            , Tw.border_t
            , Tw.border_simple TC.borderDefault
            , Tw.bg_simple TC.bgSubtle
            , Tw.p Th.s4
            ]
        ]
        [ Html.div
            [ classes
                [ Tw.mx_auto
                , Tw.grid
                , TwEx.max_w_5xl
                , Tw.grid_cols_1
                , Tw.gap Th.s6
                , Bp.md [ Tw.grid_cols_3 ]
                ]
            ]
            (List.map (viewCard config.newTabHint) config.cards
                ++ (case config.feeds of
                        Just fg ->
                            [ viewFeedGroup config.newTabHint fg ]

                        Nothing ->
                            []
                   )
            )
        ]


viewCard : String -> Card -> Html msg
viewCard newTabHint card =
    Html.a
        [ Attr.href card.href
        , Attr.target "_blank"
        , Attr.rel "noopener noreferrer"
        , classes
            [ Tw.block
            , Tw.rounded_lg
            , Tw.p Th.s4
            , Tw.text_left
            , Tw.bg_simple TC.bgSubtle
            , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
            , Bp.hover [ Tw.bg_simple TC.bgPage ]
            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
            ]
        ]
        [ Html.div
            [ classes [ Tw.mb Th.s3, Tw.flex, Tw.items_center ] ]
            [ Html.div
                [ classes [ Tw.mr Th.s2, Tw.text_simple TC.brand ] ]
                [ card.icon
                    |> FeatherIcons.withSize 32
                    |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
                ]
            , Html.h3 [ classes [ Tw.type_h3 ] ] [ Html.text card.title ]
            ]
        , Html.p [ classes [ Tw.type_caption, Tw.text_simple TC.textMuted ] ] [ Html.text card.description ]
        , Html.span [ classes [ Tw.sr_only ] ] [ Html.text (" " ++ newTabHint) ]
        ]


viewFeedGroup : String -> FeedGroup -> Html msg
viewFeedGroup newTabHint fg =
    Html.div
        [ classes [ Tw.p Th.s4, Tw.text_left ] ]
        [ Html.div
            [ classes [ Tw.mb Th.s3, Tw.flex, Tw.items_center ] ]
            [ Html.div
                [ classes [ Tw.mr Th.s2, Tw.text_simple TC.brand ] ]
                [ fg.icon
                    |> FeatherIcons.withSize 32
                    |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
                ]
            , Html.h3 [ classes [ Tw.type_h3 ] ] [ Html.text fg.title ]
            ]
        , Html.p [ classes [ Tw.mb Th.s3, Tw.type_caption, Tw.text_simple TC.textMuted ] ] [ Html.text fg.description ]
        , Html.div
            [ classes [ Tw.text_center, Tw.type_caption ] ]
            (renderFeedLinks newTabHint fg.links)
        ]


renderFeedLinks : String -> List { label : String, href : String } -> List (Html msg)
renderFeedLinks newTabHint links =
    case links of
        [] ->
            []

        [ single ] ->
            [ viewFeedLink newTabHint single ]

        first :: rest ->
            viewFeedLink newTabHint first
                :: List.concatMap (\l -> [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text " | " ], viewFeedLink newTabHint l ]) rest


viewFeedLink : String -> { label : String, href : String } -> Html msg
viewFeedLink newTabHint link =
    Html.a
        [ Attr.href link.href
        , Attr.target "_blank"
        , Attr.rel "noopener noreferrer"
        , classes
            [ Tw.mx Th.s1
            , Tw.text_simple TC.brand
            , Tw.no_underline
            , Tw.rounded
            , Bp.hover [ Tw.underline ]
            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
            ]
        ]
        [ Html.text link.label
        , Html.span [ classes [ Tw.sr_only ] ] [ Html.text (" " ++ newTabHint) ]
        ]
