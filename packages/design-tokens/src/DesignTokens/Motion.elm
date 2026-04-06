module DesignTokens.Motion exposing
    ( durationFast
    , durationBase
    , durationSlow
    , easingStandard
    , easingDecelerate
    , easingAccelerate
    )


{-| Motion tokens — durations (ms) and cubic-bezier easings. -}


{-| Hover states, focus rings, button fills. -}
durationFast : Int
durationFast =
    150

{-| Default: card lift, menu open, accordion expand. -}
durationBase : Int
durationBase =
    300

{-| Page-level transitions, large content reveals. -}
durationSlow : Int
durationSlow =
    500



{-| Default easing for elements that both enter and exit. -}
easingStandard : { p1x : Float, p1y : Float, p2x : Float, p2y : Float }
easingStandard =
    { p1x = 0.4
    , p1y = 0.0
    , p2x = 0.2
    , p2y = 1.0
    }

{-| Elements entering the screen. -}
easingDecelerate : { p1x : Float, p1y : Float, p2x : Float, p2y : Float }
easingDecelerate =
    { p1x = 0.0
    , p1y = 0.0
    , p2x = 0.2
    , p2y = 1.0
    }

{-| Elements leaving the screen. -}
easingAccelerate : { p1x : Float, p1y : Float, p2x : Float, p2y : Float }
easingAccelerate =
    { p1x = 0.4
    , p1y = 0.0
    , p2x = 1.0
    , p2y = 1.0
    }
