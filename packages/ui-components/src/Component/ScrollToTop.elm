module Component.ScrollToTop exposing (view)

{-| Floating scroll-to-top button.

@docs view

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


{-| Floating scroll-to-top button. Renders nothing when `visible` is `False`.
When `clearRightColumn` is `True`, shifts the button on desktop (`md:right-52`) to avoid overlapping right-hand filters.
-}
view : { visible : Bool, onClick : msg, label : String, clearRightColumn : Bool } -> Html msg
view config =
    if not config.visible then
        Html.text ""

    else
        Html.button
            [ Events.onClick config.onClick
            , Attr.type_ "button"
            , Attr.attribute "aria-label" config.label
            , classes
                ([ Tw.fixed
                 , TwEx.bottom_4
                 , Tw.z_50
                 , Tw.p Th.s3
                 , Tw.rounded_full
                 , Tw.bg_simple TC.brand
                 , Tw.text_simple TC.textOnDark
                 , Tw.shadow_lg
                 , Tw.cursor_pointer
                 , Bp.withVariant "motion-safe" [ Tw.transition_opacity ]
                 , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
                 ]
                    ++ (if config.clearRightColumn then
                            [ TwEx.right_4, Bp.md [ TwEx.right_52 ] ]

                        else
                            [ TwEx.right_4 ]
                       )
                )
            ]
            [ FeatherIcons.arrowUp
                |> FeatherIcons.withSize 24
                |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
            ]
