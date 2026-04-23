module DesignTokens.Accessibility exposing
    ( ringAccentColor
    , ringAccentOffsetPx
    , ringAccentTailwindClass
    , ringAccentWidthPx
    , ringBrandColor
    , ringBrandOffsetPx
    , ringBrandTailwindClass
    , ringBrandWidthPx
    , ringErrorColor
    , ringErrorOffsetPx
    , ringErrorTailwindClass
    , ringErrorWidthPx
    )

{-| Focus ring tokens for accessible interactive elements.
-}


{-| Default focus ring — brand-colored. Use for most interactive elements.
-}
ringBrandWidthPx : Int
ringBrandWidthPx =
    2


ringBrandOffsetPx : Int
ringBrandOffsetPx =
    2


ringBrandColor : String
ringBrandColor =
    "#05131D"


ringBrandTailwindClass : String
ringBrandTailwindClass =
    "focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-brand"


{-| Accent focus ring — yellow. Use for CTAs on dark backgrounds.
-}
ringAccentWidthPx : Int
ringAccentWidthPx =
    2


ringAccentOffsetPx : Int
ringAccentOffsetPx =
    2


ringAccentColor : String
ringAccentColor =
    "#FAC80A"


ringAccentTailwindClass : String
ringAccentTailwindClass =
    "focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-brand-yellow"


{-| Error focus ring — red. Use for invalid form fields.
-}
ringErrorWidthPx : Int
ringErrorWidthPx =
    2


ringErrorOffsetPx : Int
ringErrorOffsetPx =
    2


ringErrorColor : String
ringErrorColor =
    "#C91A09"


ringErrorTailwindClass : String
ringErrorTailwindClass =
    "focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-brand-red"
