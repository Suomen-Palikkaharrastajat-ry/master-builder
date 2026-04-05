module DesignTokens.Colors exposing
    ( legoYellow
    , legoBlack
    , legoWhite
    , red
    , skinToneYellow
    , skinToneLightNougat
    , skinToneNougat
    , skinToneDarkNougat
    , rainbowSalmon
    , rainbowLightOrange
    , rainbowYellow
    , rainbowMediumGreen
    , rainbowBrightLightBlue
    , rainbowLightLilac
    , rainbowMediumLavender
    , textPrimary
    , textOnDark
    , textMuted
    , textSubtle
    , backgroundPage
    , backgroundDark
    , backgroundSubtle
    , backgroundAccent
    , borderDefault
    , borderBrand
    , brandRed
    )


{-| Brand, skin-tone, rainbow, and semantic color tokens.

All values are CSS hex strings (e.g. "#05131D").

-}


{-| Yellow — Classic LEGO minifig yellow. Brand accent color. -}
legoYellow : String
legoYellow =
    "#FAC80A"

{-| Black — Primary brand color. -}
legoBlack : String
legoBlack =
    "#05131D"

{-| White — Use for eye highlights and text on dark/brand-colored backgrounds. -}
legoWhite : String
legoWhite =
    "#FFFFFF"

{-| Red — Accent colour from the Blacktron series. Use for highlights, danger states, and emphasis. -}
red : String
red =
    "#C91A09"



{-| Yellow — Classic LEGO minifig yellow. Brand accent color. -}
skinToneYellow : String
skinToneYellow =
    "#FAC80A"

{-| Light Nougat — Light skin tone. Contrast on white: 1.4:1 — decorative only. -}
skinToneLightNougat : String
skinToneLightNougat =
    "#F6D7B3"

{-| Nougat — Medium skin tone. Contrast on black: 6.7:1 (AA). -}
skinToneNougat : String
skinToneNougat =
    "#D09168"

{-| Dark Nougat — Dark skin tone. Contrast on white: 4.4:1 (AA large text). -}
skinToneDarkNougat : String
skinToneDarkNougat =
    "#AD6140"



{-| Salmon — Red -}
rainbowSalmon : String
rainbowSalmon =
    "#F2705E"

{-| Light Orange — Orange -}
rainbowLightOrange : String
rainbowLightOrange =
    "#F9BA61"

{-| Yellow — Yellow -}
rainbowYellow : String
rainbowYellow =
    "#FAC80A"

{-| Medium Green — Green -}
rainbowMediumGreen : String
rainbowMediumGreen =
    "#73DCA1"

{-| Bright Light Blue — Blue -}
rainbowBrightLightBlue : String
rainbowBrightLightBlue =
    "#9FC3E9"

{-| Light Lilac — Indigo -}
rainbowLightLilac : String
rainbowLightLilac =
    "#9195CA"

{-| Medium Lavender — Violet -}
rainbowMediumLavender : String
rainbowMediumLavender =
    "#AC78BA"



{-| Primary body text; use on white or light-gray backgrounds. -}
textPrimary : String
textPrimary =
    "#05131D"

{-| Text on dark or brand-colored backgrounds. -}
textOnDark : String
textOnDark =
    "#FFFFFF"

{-| Secondary labels, captions, helper text on light backgrounds. -}
textMuted : String
textMuted =
    "#6B7280"

{-| De-emphasised metadata; use only for large text. -}
textSubtle : String
textSubtle =
    "#9CA3AF"

{-| Default page/document background. -}
backgroundPage : String
backgroundPage =
    "#FFFFFF"

{-| Dark section backgrounds. Pair with text-on-dark. -}
backgroundDark : String
backgroundDark =
    "#05131D"

{-| Light card and section backgrounds. -}
backgroundSubtle : String
backgroundSubtle =
    "#F9FAFB"

{-| Brand accent CTA color. Always pair with text-primary. -}
backgroundAccent : String
backgroundAccent =
    "#FAC80A"

{-| Standard card and section divider borders. -}
borderDefault : String
borderDefault =
    "#E5E7EB"

{-| Brand-colored borders, left-accent rules, focus rings. -}
borderBrand : String
borderBrand =
    "#05131D"

{-| Error states, destructive actions, required field indicators. -}
brandRed : String
brandRed =
    "#C91A09"
