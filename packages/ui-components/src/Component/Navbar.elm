module Component.Navbar exposing (NavLink, Variant(..), view)

{-| Top navigation bar component.

Supports three variants:

  - `Light` — white background with border, for page-level navbars.
  - `Dark` — brand-colour background with shadow, for the main site navbar.
  - `Compact` — brand-colour h-14 bar with square icon + title, full-width layout.

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


type alias NavLink =
    { label : String
    , href : String
    , mobileOnly : Bool
    , isActive : Bool
    }


type Variant
    = Light
    | Dark
    | Compact


view :
    { logo : Html msg
    , links : List NavLink
    , mobileMenuToggle : Maybe (Html msg)
    , action : Maybe (Html msg)
    , sticky : Bool
    , variant : Variant
    }
    -> Html msg
view config =
    case config.variant of
        Compact ->
            viewCompact config

        _ ->
            viewStandard config


viewStandard :
    { logo : Html msg
    , links : List NavLink
    , mobileMenuToggle : Maybe (Html msg)
    , action : Maybe (Html msg)
    , sticky : Bool
    , variant : Variant
    }
    -> Html msg
viewStandard config =
    Html.nav
        [ classes (navTw config.variant config.sticky) ]
        [ Html.div
            [ classes [ TwEx.max_w_5xl, Tw.mx_auto, Tw.px Th.s4 ] ]
            [ Html.div
                [ classes [ Tw.flex, Tw.items_center, Tw.py Th.s2, Bp.sm [ Tw.py Th.s3 ] ] ]
                ([ Html.div [ classes [ Tw.shrink_0, Tw.mr_auto ] ] [ config.logo ]
                 , Html.ul
                    [ classes [ Bp.sm [ Tw.flex ], Tw.hidden, Tw.flex_wrap, Tw.gap Th.s0_dot_5, Tw.list_none, Tw.m Th.s0, Tw.p Th.s0 ] ]
                    (config.links
                        |> List.filter (not << .mobileOnly)
                        |> List.map (viewLink config.variant)
                    )
                 ]
                    ++ (case config.action of
                            Just btn ->
                                [ Html.div [] [ btn ] ]

                            Nothing ->
                                []
                       )
                    ++ (case config.mobileMenuToggle of
                            Just toggle ->
                                [ toggle ]

                            Nothing ->
                                []
                       )
                )
            ]
        ]


viewCompact :
    { logo : Html msg
    , links : List NavLink
    , mobileMenuToggle : Maybe (Html msg)
    , action : Maybe (Html msg)
    , sticky : Bool
    , variant : Variant
    }
    -> Html msg
viewCompact config =
    Html.header
        [ classes
            ([ Tw.bg_simple TC.brand, Tw.border_b, Tw.border_simple TC.brand ]
                ++ (if config.sticky then
                        [ Tw.sticky, TwEx.top_0, Tw.z_40, Bp.md [ Tw.relative ] ]

                    else
                        []
                   )
            )
        ]
        [ Html.div
            [ classes [ Tw.flex, Tw.items_center, Tw.justify_between, Tw.px Th.s4, Tw.h Th.s14 ] ]
            ([ Html.div [ classes [ Tw.shrink_0 ] ] [ config.logo ]
             , Html.ul
                [ classes [ Bp.md [ Tw.flex ], Tw.hidden, Tw.flex_wrap, Tw.gap Th.s0_dot_5, Tw.list_none, Tw.m Th.s0, Tw.p Th.s0 ] ]
                (config.links
                    |> List.filter (not << .mobileOnly)
                    |> List.map (viewLink Dark)
                )
             ]
                ++ (case config.action of
                        Just btn ->
                            [ Html.div [] [ btn ] ]

                        Nothing ->
                            []
                   )
                ++ (case config.mobileMenuToggle of
                        Just toggle ->
                            [ toggle ]

                        Nothing ->
                            []
                   )
            )
        ]


navTw : Variant -> Bool -> List Tw.Tailwind
navTw variant sticky =
    (case variant of
        Light ->
            [ Tw.bg_simple Th.white, Tw.border_b, Tw.border_simple TC.borderDefault ]

        Dark ->
            [ Tw.bg_simple TC.brand, Tw.shadow_md ]

        Compact ->
            [ Tw.bg_simple TC.brand, Tw.border_b, Tw.border_simple TC.brand ]
    )
        ++ (if sticky then
                [ Tw.sticky, TwEx.top_0, Tw.z_50, Bp.sm [ Tw.relative ] ]

            else
                []
           )


viewLink : Variant -> NavLink -> Html msg
viewLink variant link =
    Html.li []
        [ Html.a
            [ Attr.href link.href
            , classes
                ([ Tw.font_medium
                 , Tw.px Th.s2
                 , Bp.sm [ Tw.px Th.s3 ]
                 , Tw.py Th.s1
                 , Tw.min_h Th.s11
                 , Tw.rounded
                 , Tw.transition_colors
                 , Tw.type_body_small
                 , Tw.cursor_pointer
                 ]
                    ++ linkVariantTw variant link.isActive
                )
            ]
            [ Html.text link.label ]
        ]


linkVariantTw : Variant -> Bool -> List Tw.Tailwind
linkVariantTw variant isActive =
    case variant of
        Light ->
            [ if isActive then
                Tw.text_simple TC.textPrimary

              else
                Tw.text_simple TC.textMuted
            , Bp.hover [ Tw.text_simple TC.textPrimary ]
            , Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
            ]

        Dark ->
            [ if isActive then
                Tw.text_simple TC.brandYellow

              else
                TwEx.text_white_80
            , Bp.hover [ Tw.text_simple TC.brandYellow ]
            , Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
            ]

        Compact ->
            [ if isActive then
                Tw.text_simple TC.brandYellow

              else
                TwEx.text_white_80
            , Bp.hover [ Tw.text_simple TC.brandYellow ]
            , Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
            ]
