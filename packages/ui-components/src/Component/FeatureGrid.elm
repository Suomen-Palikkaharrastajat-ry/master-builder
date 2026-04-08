module Component.FeatureGrid exposing (Feature, view)

{-| Feature-highlight grid component.
-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


type alias Feature msg =
    { icon : Maybe (Html msg)
    , href : Maybe String
    , title : String
    , description : List (Html msg)
    }


view : { columns : Int, features : List (Feature msg) } -> Html msg
view config =
    Html.div
        [ classes [ Tw.py Th.s12 ] ]
        [ Html.div
            [ classes (gridTw config.columns) ]
            (List.map viewFeature config.features)
        ]


viewFeature : Feature msg -> Html msg
viewFeature feature =
    let
        content =
            [ case feature.icon of
                Just ico ->
                    Html.div
                        [ classes
                            [ Tw.mb Th.s4
                            , Tw.flex
                            , Tw.h Th.s10
                            , Tw.w Th.s10
                            , Tw.items_center
                            , Tw.justify_center
                            , Tw.rounded_lg
                            , Tw.bg_simple TC.brandYellow
                            , Tw.text_simple TC.brand
                            ]
                        ]
                        [ ico ]

                Nothing ->
                    Html.text ""
            , Html.h3
                [ classes [ Tw.type_h4, TwEx.leading_7, Tw.text_simple TC.textPrimary ] ]
                [ Html.text feature.title ]
            , Html.div
                [ classes [ Tw.mt Th.s2, Tw.type_caption, TwEx.leading_7, Tw.text_simple TC.textMuted, TwEx.p_my_0, TwEx.p_text_inherit ] ]
                feature.description
            ]
    in
    case feature.href of
        Just url ->
            Html.a
                [ Attr.href url
                , classes
                    [ Tw.flex
                    , Tw.flex_col
                    , Tw.no_underline
                    , Tw.rounded_lg
                    , Tw.p Th.s3
                    , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                    , Bp.hover [ TwEx.bg_brand_5 ]
                    , Bp.focus [ Tw.outline_none ]
                    , Bp.focus_visible [ Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                    ]
                ]
                content

        Nothing ->
            Html.div [ classes [ Tw.flex, Tw.flex_col ] ] content


gridTw : Int -> List Tw.Tailwind
gridTw columns =
    [ Tw.grid, Tw.gap_x Th.s8, Tw.gap_y Th.s10 ]
        ++ (case columns of
                2 ->
                    [ Bp.sm [ Tw.grid_cols_2 ] ]

                3 ->
                    [ Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_3 ] ]

                4 ->
                    [ Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_4 ] ]

                _ ->
                    [ Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_3 ] ]
           )
