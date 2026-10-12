module Component.Button exposing (Button, Variant(..), Size(..), new, submit, link, withVariant, withSize, withIcon, iconOnly, withDisabled, withLoading, withPressed, withTarget, toHtml, view, viewLink)

{-| Button component with multiple variants, sizes, and builder API.

@docs Button, Variant, Size, new, submit, link, withVariant, withSize, withIcon, iconOnly, withDisabled, withLoading, withPressed, withTarget, toHtml, view, viewLink

-}

import Component.Spinner as Spinner
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Visual button variants.
-}
type Variant
    = Primary
    | Secondary
    | Ghost
    | Danger
    | Accent


{-| Button sizes.
-}
type Size
    = Small
    | Medium
    | Large


{-| Opaque button configuration builder.
-}
type Button msg
    = Button (Config msg)


type ButtonKind msg
    = Action msg
    | Submit
    | Link String (Maybe String)


type alias Config msg =
    { label : String
    , kind : ButtonKind msg
    , variant : Variant
    , size : Size
    , icon : Maybe FeatherIcons.Icon
    , isIconOnly : Bool
    , disabled : Bool
    , loading : Bool
    , pressed : Maybe Bool
    }


{-| Creates a new clickable button.
-}
new : { label : String, onClick : msg } -> Button msg
new config =
    Button
        { label = config.label
        , kind = Action config.onClick
        , variant = Primary
        , size = Medium
        , icon = Nothing
        , isIconOnly = False
        , disabled = False
        , loading = False
        , pressed = Nothing
        }


{-| Creates a form submit button (`type="submit"`). Handled by form onSubmit.
-}
submit : { label : String } -> Button msg
submit config =
    Button
        { label = config.label
        , kind = Submit
        , variant = Primary
        , size = Medium
        , icon = Nothing
        , isIconOnly = False
        , disabled = False
        , loading = False
        , pressed = Nothing
        }


{-| Creates a link styled as a button (`<a>`).
-}
link : { label : String, href : String } -> Button msg
link config =
    Button
        { label = config.label
        , kind = Link config.href Nothing
        , variant = Primary
        , size = Medium
        , icon = Nothing
        , isIconOnly = False
        , disabled = False
        , loading = False
        , pressed = Nothing
        }


{-| Sets the button variant (defaults to `Primary`).
-}
withVariant : Variant -> Button msg -> Button msg
withVariant variant (Button cfg) =
    Button { cfg | variant = variant }


{-| Sets the button size (defaults to `Medium`).
-}
withSize : Size -> Button msg -> Button msg
withSize size (Button cfg) =
    Button { cfg | size = size }


{-| Adds a leading decorative icon, sized according to button size.
-}
withIcon : FeatherIcons.Icon -> Button msg -> Button msg
withIcon icon_ (Button cfg) =
    Button { cfg | icon = Just icon_ }


{-| Hides the label visually; label becomes an `aria-label`.
-}
iconOnly : Button msg -> Button msg
iconOnly (Button cfg) =
    Button { cfg | isIconOnly = True }


{-| Sets the disabled state.
-}
withDisabled : Bool -> Button msg -> Button msg
withDisabled disabled (Button cfg) =
    Button { cfg | disabled = disabled }


{-| Sets loading state; displays a Spinner and marks element `aria-busy="true"`.
-}
withLoading : Bool -> Button msg -> Button msg
withLoading loading (Button cfg) =
    Button { cfg | loading = loading }


{-| Sets `aria-pressed` state for toggle buttons.
-}
withPressed : Maybe Bool -> Button msg -> Button msg
withPressed pressed (Button cfg) =
    Button { cfg | pressed = pressed }


{-| Sets the `target` attribute for link buttons.
-}
withTarget : String -> Button msg -> Button msg
withTarget target (Button cfg) =
    case cfg.kind of
        Link href _ ->
            Button { cfg | kind = Link href (Just target) }

        _ ->
            Button cfg


{-| Renders the button to HTML.
-}
toHtml : Button msg -> Html msg
toHtml (Button config) =
    let
        isInactive =
            config.disabled || config.loading

        iconSize =
            iconSizeFor config.size

        renderedIcon =
            config.icon
                |> Maybe.map
                    (\i ->
                        i
                            |> FeatherIcons.withSize iconSize
                            |> FeatherIcons.toHtml
                                [ Attr.attribute "aria-hidden" "true"
                                , Attr.attribute "focusable" "false"
                                ]
                    )

        content =
            if config.loading then
                [ Spinner.view { size = spinnerSizeFor config.size, label = config.label } ]

            else if config.isIconOnly then
                case renderedIcon of
                    Just ic ->
                        [ ic ]

                    Nothing ->
                        [ Html.span [ classes [ Tw.sr_only ] ] [ Html.text config.label ] ]

            else
                case renderedIcon of
                    Just ic ->
                        [ ic, Html.span [] [ Html.text config.label ] ]

                    Nothing ->
                        [ Html.text config.label ]

        baseClasses =
            classes
                (buttonTw config.variant config.size
                    ++ (if isInactive then
                            [ Tw.cursor_not_allowed, Tw.opacity_50 ]

                        else
                            []
                       )
                )

        loadingAttrs =
            if config.loading then
                [ Attr.attribute "aria-busy" "true"
                , Attr.attribute "aria-label" config.label
                ]

            else
                []

        iconOnlyAttrs =
            if config.isIconOnly && not config.loading then
                [ Attr.attribute "aria-label" config.label ]

            else
                []

        pressedAttrs =
            case config.pressed of
                Just pressed ->
                    [ Attr.attribute "aria-pressed"
                        (if pressed then
                            "true"

                         else
                            "false"
                        )
                    ]

                Nothing ->
                    []
    in
    case config.kind of
        Action onClick ->
            let
                clickAttrs =
                    if isInactive then
                        []

                    else
                        [ Events.onClick onClick ]
            in
            Html.button
                ([ baseClasses
                 , Attr.type_ "button"
                 , Attr.disabled isInactive
                 ]
                    ++ iconOnlyAttrs
                    ++ loadingAttrs
                    ++ pressedAttrs
                    ++ clickAttrs
                )
                content

        Submit ->
            Html.button
                ([ baseClasses
                 , Attr.type_ "submit"
                 , Attr.disabled isInactive
                 ]
                    ++ iconOnlyAttrs
                    ++ loadingAttrs
                    ++ pressedAttrs
                )
                content

        Link href maybeTarget ->
            let
                targetAttrs =
                    case maybeTarget of
                        Just t ->
                            [ Attr.target t ]

                        Nothing ->
                            []

                linkAttrs =
                    if isInactive then
                        [ Attr.attribute "aria-disabled" "true"
                        , Attr.attribute "tabindex" "-1"
                        ]

                    else
                        [ Attr.href href ]
            in
            Html.a
                ([ baseClasses ]
                    ++ iconOnlyAttrs
                    ++ linkAttrs
                    ++ targetAttrs
                )
                content


{-| Original record-based Button view for backwards compatibility.
-}
view : { label : String, variant : Variant, size : Size, onClick : msg, disabled : Bool, loading : Bool, ariaPressedState : Maybe Bool } -> Html msg
view config =
    new { label = config.label, onClick = config.onClick }
        |> withVariant config.variant
        |> withSize config.size
        |> withDisabled config.disabled
        |> withLoading config.loading
        |> withPressed config.ariaPressedState
        |> toHtml


{-| Original record-based Button viewLink for backwards compatibility.
-}
viewLink : { label : String, variant : Variant, size : Size, href : String, target : Maybe String } -> Html msg
viewLink config =
    let
        btn =
            link { label = config.label, href = config.href }
                |> withVariant config.variant
                |> withSize config.size
    in
    case config.target of
        Just t ->
            btn |> withTarget t |> toHtml

        Nothing ->
            btn |> toHtml


iconSizeFor : Size -> Float
iconSizeFor size =
    case size of
        Small ->
            14

        Medium ->
            16

        Large ->
            20


spinnerSizeFor : Size -> Spinner.Size
spinnerSizeFor size =
    case size of
        Small ->
            Spinner.Small

        Medium ->
            Spinner.Small

        Large ->
            Spinner.Medium


buttonTw : Variant -> Size -> List Tw.Tailwind
buttonTw variant size =
    [ Tw.inline_flex
    , Tw.items_center
    , Tw.justify_center
    , Tw.gap Th.s2
    , Tw.font_semibold
    , Tw.rounded
    , Tw.transition_all
    , Tw.cursor_pointer
    , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2 ]
    ]
        ++ variantTw variant
        ++ sizeTw size


variantTw : Variant -> List Tw.Tailwind
variantTw variant =
    case variant of
        Primary ->
            [ Tw.bg_simple TC.brandYellow
            , Tw.text_simple TC.brand
            , Bp.hover [ Tw.opacity_90 ]
            , Bp.focus_visible [ TwEx.ring_brand_yellow ]
            ]

        Accent ->
            [ Tw.bg_simple TC.brandYellow
            , Tw.text_simple TC.brand
            , Bp.hover [ Tw.opacity_90 ]
            , Bp.focus_visible [ TwEx.ring_brand_yellow ]
            ]

        Secondary ->
            [ Tw.bg_simple Th.white
            , Tw.text_simple TC.brand
            , Tw.border
            , Tw.border_simple TC.brand
            , Bp.hover [ Tw.bg_color (Th.gray Th.s50) ]
            , Bp.focus_visible [ TwEx.ring_brand ]
            ]

        Ghost ->
            [ TwEx.bg_transparent
            , Tw.text_simple TC.brand
            , Bp.hover [ TwEx.bg_brand_5 ]
            , Bp.focus_visible [ TwEx.ring_brand ]
            ]

        Danger ->
            [ Tw.bg_color (Th.red Th.s600)
            , Tw.text_simple Th.white
            , Bp.hover [ Tw.bg_color (Th.red Th.s700) ]
            , Bp.focus_visible [ Tw.ring_color (Th.red Th.s500) ]
            ]


sizeTw : Size -> List Tw.Tailwind
sizeTw size =
    case size of
        Small ->
            [ Tw.px Th.s3, Tw.py Th.s1_dot_5, Tw.type_body_small ]

        Medium ->
            [ Tw.px Th.s4, Tw.py Th.s3, Tw.type_body_small ]

        Large ->
            [ Tw.px Th.s6, Tw.py Th.s3, Tw.type_body ]
