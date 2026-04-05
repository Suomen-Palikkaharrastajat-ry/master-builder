module DesignTokens.Typography exposing
    ( fontFamily
    , displaySizePx
    , displaySizeRem
    , displayWeight
    , displayLineHeight
    , heading1SizePx
    , heading1SizeRem
    , heading1Weight
    , heading1LineHeight
    , heading2SizePx
    , heading2SizeRem
    , heading2Weight
    , heading2LineHeight
    , heading3SizePx
    , heading3SizeRem
    , heading3Weight
    , heading3LineHeight
    , heading4SizePx
    , heading4SizeRem
    , heading4Weight
    , heading4LineHeight
    , bodySizePx
    , bodySizeRem
    , bodyWeight
    , bodyLineHeight
    , bodySmallSizePx
    , bodySmallSizeRem
    , bodySmallWeight
    , bodySmallLineHeight
    , captionSizePx
    , captionSizeRem
    , captionWeight
    , captionLineHeight
    , monoSizePx
    , monoSizeRem
    , monoWeight
    , monoLineHeight
    , overlineSizePx
    , overlineSizeRem
    , overlineWeight
    , overlineLineHeight
    )


{-| Typography tokens — font family and type scale. -}


{-| Primary font stack. -}
fontFamily : List String
fontFamily =
    [ "Outfit"
    , "system-ui"
    , "sans-serif"
    ]


{-| Hero headlines and landing-page titles only. -}
displaySizePx : Int
displaySizePx =
    48


displaySizeRem : Float
displaySizeRem =
    3.0


displayWeight : Int
displayWeight =
    700


displayLineHeight : Float
displayLineHeight =
    1.1


{-| Page-level headings (one per page). -}
heading1SizePx : Int
heading1SizePx =
    30


heading1SizeRem : Float
heading1SizeRem =
    1.875


heading1Weight : Int
heading1Weight =
    700


heading1LineHeight : Float
heading1LineHeight =
    1.2


{-| Section headings. -}
heading2SizePx : Int
heading2SizePx =
    24


heading2SizeRem : Float
heading2SizeRem =
    1.5


heading2Weight : Int
heading2Weight =
    700


heading2LineHeight : Float
heading2LineHeight =
    1.3


{-| Sub-section headings. -}
heading3SizePx : Int
heading3SizePx =
    20


heading3SizeRem : Float
heading3SizeRem =
    1.25


heading3Weight : Int
heading3Weight =
    600


heading3LineHeight : Float
heading3LineHeight =
    1.35


{-| Card and widget headings. Use below Heading3. -}
heading4SizePx : Int
heading4SizePx =
    18


heading4SizeRem : Float
heading4SizeRem =
    1.125


heading4Weight : Int
heading4Weight =
    600


heading4LineHeight : Float
heading4LineHeight =
    1.4


{-| Default body copy. Minimum size for accessible reading. -}
bodySizePx : Int
bodySizePx =
    16


bodySizeRem : Float
bodySizeRem =
    1.0


bodyWeight : Int
bodyWeight =
    400


bodyLineHeight : Float
bodyLineHeight =
    1.6


{-| Secondary labels, UI controls, and form hints. -}
bodySmallSizePx : Int
bodySmallSizePx =
    14


bodySmallSizeRem : Float
bodySmallSizeRem =
    0.875


bodySmallWeight : Int
bodySmallWeight =
    500


bodySmallLineHeight : Float
bodySmallLineHeight =
    1.5


{-| Image captions, footnotes, and metadata. -}
captionSizePx : Int
captionSizePx =
    14


captionSizeRem : Float
captionSizeRem =
    0.875


captionWeight : Int
captionWeight =
    400


captionLineHeight : Float
captionLineHeight =
    1.4


{-| Hex values, IDs, and code snippets. -}
monoSizePx : Int
monoSizePx =
    14


monoSizeRem : Float
monoSizeRem =
    0.875


monoWeight : Int
monoWeight =
    400


monoLineHeight : Float
monoLineHeight =
    1.6


{-| Section category labels. Always uppercase. -}
overlineSizePx : Int
overlineSizePx =
    12


overlineSizeRem : Float
overlineSizeRem =
    0.75


overlineWeight : Int
overlineWeight =
    600


overlineLineHeight : Float
overlineLineHeight =
    1.4
