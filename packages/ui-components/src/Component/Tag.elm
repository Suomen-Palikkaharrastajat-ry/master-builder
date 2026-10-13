module Component.Tag exposing (view)

{-| Dismissible tag / chip component.
-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| `onRemove.label` is the accessible name of the remove button ("Poista X").
-}
view : { label : String, onRemove : Maybe { msg : msg, label : String } } -> Html msg
view config =
    Html.span
        [ classes
            [ Tw.inline_flex
            , Tw.items_center
            , Tw.gap Th.s1
            , Tw.rounded_full
            , Tw.px Th.s2_dot_5
            , Tw.py Th.s0_dot_5
            , Tw.text_xs
            , Tw.font_medium
            , TwEx.bg_brand_10
            , Tw.text_simple TC.brand
            ]
        ]
        (Html.text config.label
            :: (case config.onRemove of
                    Nothing ->
                        []

                    Just remove ->
                        [ Html.button
                            [ Attr.type_ "button"
                            , Attr.attribute "aria-label" remove.label
                            , classes
                                [ Tw.ml Th.s0_dot_5
                                , Tw.inline_flex
                                , Tw.items_center
                                , Tw.justify_center
                                , Tw.w Th.s3_dot_5
                                , Tw.h Th.s3_dot_5
                                , Tw.rounded_full
                                , Bp.hover [ TwEx.bg_brand_20 ]
                                , Tw.transition_colors
                                , Tw.cursor_pointer
                                ]
                            , Events.onClick remove.msg
                            ]
                            [ FeatherIcons.x |> FeatherIcons.withSize 10 |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true" ] ]
                        ]
               )
        )
