module Component.Toast exposing (Toast, Variant(..), view, viewToast, region)

{-| Toast notification component and aria-live region.

@docs Toast, Variant, view, viewToast, region

-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Html.Keyed
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Toast visual variant.
-}
type Variant
    = Default
    | Success
    | Warning
    | Danger


{-| Configuration for a single toast item.
-}
type alias Toast msg =
    { id : String
    , title : Maybe String
    , body : String
    , variant : Variant
    , onClose : Maybe msg
    }


{-| Renders a single toast notification.
-}
viewToast : Toast msg -> Html msg
viewToast toast =
    renderToast Nothing toast


{-| Backwards-compatible view taking a record with a required title string.
Empty string title is treated as `Nothing`.
-}
view :
    { title : String
    , body : String
    , variant : Variant
    , onClose : Maybe msg
    }
    -> Html msg
view config =
    viewToast
        { id = ""
        , title =
            if String.isEmpty (String.trim config.title) then
                Nothing

            else
                Just config.title
        , body = config.body
        , variant = config.variant
        , onClose = config.onClose
        }


{-| Live region container for managing and announcing toast notifications.
Always rendered so `aria-live` announces newly added toasts.
-}
region : { label : String, closeLabel : String } -> List (Toast msg) -> Html msg
region config toasts =
    Html.div
        [ Attr.attribute "role" "region"
        , Attr.attribute "aria-label" config.label
        , classes
            [ Tw.fixed
            , TwEx.bottom_0
            , TwEx.right_0
            , Tw.z_50
            , Tw.p Th.s4
            , Tw.pointer_events_none
            , Tw.w_full
            , TwEx.max_w_sm
            ]
        ]
        [ Html.Keyed.node "div"
            [ Attr.attribute "aria-live" "polite"
            , Attr.attribute "aria-relevant" "additions"
            , classes [ Tw.flex, Tw.flex_col, Tw.gap Th.s2, Tw.w_full ]
            ]
            (List.map (\t -> ( t.id, renderToast (Just config.closeLabel) t )) toasts)
        ]


renderToast : Maybe String -> Toast msg -> Html msg
renderToast maybeCloseLabel config =
    let
        closeLabel =
            Maybe.withDefault "Sulje" maybeCloseLabel

        roleAttr =
            case config.variant of
                Danger ->
                    Attr.attribute "role" "alert"

                _ ->
                    Attr.attribute "role" "status"
    in
    Html.div
        [ classes
            [ Tw.flex
            , Tw.items_start
            , Tw.gap Th.s3
            , Tw.w_full
            , TwEx.max_w_sm
            , Tw.rounded_lg
            , Tw.border
            , Tw.border_simple TC.borderDefault
            , Tw.p Th.s4
            , Tw.shadow_lg
            , Tw.bg_simple TC.bgPage
            , Tw.pointer_events_auto
            ]
        , roleAttr
        ]
        [ Html.div
            [ classes ([ Tw.mt Th.s0_dot_5, Tw.shrink_0, Tw.leading_none ] ++ iconColorTw config.variant) ]
            [ icon config.variant ]
        , Html.div [ classes [ Tw.flex_1, Tw.min_w Th.s0 ] ]
            (List.filterMap identity
                [ Maybe.map
                    (\t -> Html.p [ classes [ Tw.type_body_small, Tw.font_semibold, Tw.text_simple TC.textPrimary ] ] [ Html.text t ])
                    config.title
                , Just (Html.p [ classes [ Tw.type_body_small, Tw.text_simple TC.textMuted ] ] [ Html.text config.body ])
                ]
            )
        , case config.onClose of
            Just onClose ->
                Html.button
                    [ Attr.type_ "button"
                    , classes
                        [ Tw.shrink_0
                        , Tw.text_simple TC.textMuted
                        , Tw.rounded
                        , Bp.hover [ Tw.text_simple TC.textPrimary ]
                        , Tw.transition_colors
                        , Tw.cursor_pointer
                        , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                        ]
                    , Attr.attribute "aria-label" closeLabel
                    , Events.onClick onClose
                    ]
                    [ FeatherIcons.x
                        |> FeatherIcons.withSize 16
                        |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
                    ]

            Nothing ->
                Html.text ""
        ]


iconColorTw : Variant -> List Tw.Tailwind
iconColorTw variant =
    case variant of
        Default ->
            [ Tw.text_simple TC.brand ]

        Success ->
            [ Tw.text_simple TC.brandNougatDark ]

        Warning ->
            [ Tw.text_simple TC.brandYellow ]

        Danger ->
            [ Tw.text_simple TC.brandRed ]


icon : Variant -> Html msg
icon variant =
    (case variant of
        Default ->
            FeatherIcons.info

        Success ->
            FeatherIcons.checkCircle

        Warning ->
            FeatherIcons.alertTriangle

        Danger ->
            FeatherIcons.xCircle
    )
        |> FeatherIcons.withSize 18
        |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
