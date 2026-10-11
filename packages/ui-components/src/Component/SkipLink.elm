module Component.SkipLink exposing (view)

{-| Accessible skip link to jump directly to main content.

@docs view

-}

import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Renders a skip link. The `target` parameter should NOT include the leading `#`.
-}
view : { target : String, label : String } -> Html msg
view config =
    Html.a
        [ Attr.href ("#" ++ config.target)
        , classes
            [ Tw.sr_only
            , Bp.focus
                [ Tw.not_sr_only
                , Tw.fixed
                , TwEx.top_4
                , TwEx.left_4
                , Tw.z_50
                , Tw.px Th.s4
                , Tw.py Th.s2
                , Tw.bg_simple TC.brand
                , Tw.text_simple TC.textOnDark
                , Tw.rounded_lg
                , Tw.type_body_small
                ]
            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
            ]
        ]
        [ Html.text config.label ]
