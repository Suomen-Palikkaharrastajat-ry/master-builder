module Component.Navbar exposing (NavLink, Variant(..), view, viewAppHeader, viewBrand, viewMenuToggle)

{-| Top navigation bar component.

Supports three variants:

  - `Light` — white background with border, for page-level navbars.
  - `Dark` — brand-colour background with shadow, for the main site navbar.
  - `Compact` — brand-colour h-14 bar with square icon + title, full-width layout.

For standalone Elm applications, `viewAppHeader`, `viewBrand`, and `viewMenuToggle`
provide the standard Compact header layout and accessible controls.

@docs NavLink, Variant, view, viewAppHeader, viewBrand, viewMenuToggle

-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
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


{-| Square-logo + title link for the Compact header.
-}
viewBrand :
    { href : String
    , iconSrc : String
    , title : String
    , onClick : Maybe msg
    }
    -> Html msg
viewBrand config =
    let
        attrs =
            [ Attr.href config.href
            , classes
                [ Tw.flex
                , Tw.items_center
                , Tw.gap Th.s2
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow, Tw.rounded ]
                ]
            ]
                ++ (case config.onClick of
                        Just msg ->
                            [ Events.preventDefaultOn "click" (Decode.succeed ( msg, True )) ]

                        Nothing ->
                            []
                   )
    in
    Html.a
        attrs
        [ Html.img
            [ Attr.src config.iconSrc
            , Attr.alt ""
            , Attr.attribute "aria-hidden" "true"
            , classes [ Tw.h Th.s8, Tw.w Th.s8 ]
            ]
            []
        , Html.span
            [ classes [ Tw.type_h4, Tw.text_simple Th.white ] ]
            [ Html.text config.title ]
        ]


{-| Accessible hamburger button, visible below md.
-}
viewMenuToggle :
    { isOpen : Bool
    , onToggle : msg
    , controls : String
    , openLabel : String
    , closeLabel : String
    }
    -> Html msg
viewMenuToggle config =
    Html.button
        [ Attr.type_ "button"
        , Events.onClick config.onToggle
        , classes
            [ Bp.md [ Tw.hidden ]
            , Tw.p Th.s2
            , Tw.rounded_lg
            , Tw.text_simple Th.white
            , Tw.cursor_pointer
            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
            ]
        , Attr.attribute "aria-label"
            (if config.isOpen then
                config.closeLabel

             else
                config.openLabel
            )
        , Attr.attribute "aria-controls" config.controls
        , Attr.attribute "aria-expanded"
            (if config.isOpen then
                "true"

             else
                "false"
            )
        ]
        [ (if config.isOpen then
            FeatherIcons.x

           else
            FeatherIcons.menu
          )
            |> FeatherIcons.withSize 24
            |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
        ]


{-| App header: Compact bar with brand on the left and one trailing group.
-}
viewAppHeader :
    { brand : Html msg
    , navLabel : String
    , links : List NavLink
    , trailing : List (Html msg)
    , menuToggle : Maybe (Html msg)
    , sticky : Bool
    }
    -> Html msg
viewAppHeader config =
    let
        desktopLinks =
            config.links
                |> List.filter (not << .mobileOnly)

        desktopNav =
            if List.isEmpty desktopLinks then
                []

            else
                [ Html.nav
                    [ classes [ Tw.hidden, Bp.md [ Tw.flex ], Tw.items_center, Tw.gap Th.s4 ]
                    , Attr.attribute "aria-label" config.navLabel
                    ]
                    (List.map viewAppHeaderLink desktopLinks)
                ]

        headerClasses =
            [ Tw.bg_simple TC.brand, Tw.border_b, Tw.border_simple TC.brand ]
                ++ (if config.sticky then
                        [ Tw.sticky, Bp.md [ Tw.static ], TwEx.top_0, Tw.z_50 ]

                    else
                        []
                   )
    in
    Html.header
        [ classes headerClasses ]
        [ Html.div
            [ classes [ Tw.flex, Tw.items_center, Tw.justify_between, Tw.px Th.s4, Tw.h Th.s14 ] ]
            [ config.brand
            , Html.div
                [ classes [ Tw.flex, Tw.items_center, Tw.gap Th.s4 ] ]
                (desktopNav
                    ++ config.trailing
                    ++ (case config.menuToggle of
                            Just toggle ->
                                [ toggle ]

                            Nothing ->
                                []
                       )
                )
            ]
        ]


viewAppHeaderLink : NavLink -> Html msg
viewAppHeaderLink link =
    Html.a
        ([ Attr.href link.href
         , classes
            [ Tw.type_caption
            , TwEx.text_white_80
            , Bp.hover [ Tw.text_simple Th.white, Tw.underline ]
            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow, Tw.rounded ]
            ]
         ]
            ++ (if link.isActive then
                    [ Attr.attribute "aria-current" "page" ]

                else
                    []
               )
        )
        [ Html.text link.label ]
