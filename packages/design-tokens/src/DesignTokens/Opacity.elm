module DesignTokens.Opacity exposing
    ( opacity0
    , opacity10
    , opacity100
    , opacity25
    , opacity5
    , opacity50
    , opacity75
    , opacity90
    , opacity95
    )

{-| Opacity scale tokens (0–100).
-}


{-| Invisible — hidden before animation.
-}
opacity0 : Int
opacity0 =
    0


{-| Near-invisible — subtle hover backgrounds.
-}
opacity5 : Int
opacity5 =
    5


{-| Very faint — light overlays.
-}
opacity10 : Int
opacity10 =
    10


{-| Quarter — skeleton loading shimmers.
-}
opacity25 : Int
opacity25 =
    25


{-| Half — disabled elements, backdrop filters.
-}
opacity50 : Int
opacity50 =
    50


{-| Three-quarter — modal backdrops.
-}
opacity75 : Int
opacity75 =
    75


{-| Near-opaque — frosted-glass panels.
-}
opacity90 : Int
opacity90 =
    90


{-| Almost opaque — dropdown backgrounds.
-}
opacity95 : Int
opacity95 =
    95


{-| Fully opaque — default.
-}
opacity100 : Int
opacity100 =
    100
