module DesignTokens.Spacing exposing
    ( baseUnit
    , borderRadiusFull
    , borderRadiusLg
    , borderRadiusMd
    , borderRadiusSm
    , breakpointLg
    , breakpointMd
    , breakpointSm
    , breakpointXl
    , space1
    , space12
    , space16
    , space2
    , space3
    , space4
    , space6
    , space8
    )

{-| Spacing scale, breakpoints, and border radii.
-}


{-| Base spacing unit in pixels.
-}
baseUnit : Int
baseUnit =
    4


{-| Tight: icon padding, inline gaps.
-}
space1 : Int
space1 =
    4


{-| Compact: button padding, tag gaps.
-}
space2 : Int
space2 =
    8


{-| Small: input padding, list item gaps.
-}
space3 : Int
space3 =
    12


{-| Base: card padding, form field gaps.
-}
space4 : Int
space4 =
    16


{-| Medium: section sub-divisions.
-}
space6 : Int
space6 =
    24


{-| Large: card body padding, section gaps.
-}
space8 : Int
space8 =
    32


{-| XL: page section vertical margins.
-}
space12 : Int
space12 =
    48


{-| 2XL: hero and feature block spacing.
-}
space16 : Int
space16 =
    64


{-| Breakpoint sm in pixels.
-}
breakpointSm : Int
breakpointSm =
    640


{-| Breakpoint md in pixels.
-}
breakpointMd : Int
breakpointMd =
    768


{-| Breakpoint lg in pixels.
-}
breakpointLg : Int
breakpointLg =
    1024


{-| Breakpoint xl in pixels.
-}
breakpointXl : Int
breakpointXl =
    1280


{-| Border radius sm in pixels.
-}
borderRadiusSm : Int
borderRadiusSm =
    4


{-| Border radius md in pixels.
-}
borderRadiusMd : Int
borderRadiusMd =
    8


{-| Border radius lg in pixels.
-}
borderRadiusLg : Int
borderRadiusLg =
    12


{-| Border radius full in pixels.
-}
borderRadiusFull : Int
borderRadiusFull =
    9999
