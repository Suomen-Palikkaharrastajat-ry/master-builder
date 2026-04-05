module DesignTokens.Guide.Colors exposing
    ( ColorEntry
    , RainbowColor
    , SkinToneEntry
    , brandColors
    , rainbowColors
    , skinTones
    )

{-| Structured colour data for brand guide pages.

Use these lists to render colour palettes, swatches, and documentation.
Hex values are kept in sync with 'DesignTokens.Colors'.

-}


{-| A brand colour entry with display metadata.
-}
type alias ColorEntry =
    { hex : String
    , id : String
    , name : String
    , description : String
    , usage : List String
    }


{-| A skin-tone entry with display metadata.
-}
type alias SkinToneEntry =
    { hex : String
    , id : String
    , name : String
    , description : String
    }


{-| A rainbow colour entry with display metadata.
-}
type alias RainbowColor =
    { hex : String
    , name : String
    , description : String
    }


{-| Brand colour palette.
-}
brandColors : List ColorEntry
brandColors =
    [ { hex = "#FAC80A"
      , id = "lego-yellow"
      , name = "Yellow"
      , description = "Pääaksenttiväri painikkeisiin, korostuksiin ja CTA-elementteihin. Älä käytä tekstinä vaalealla taustalla — kontrasti ei riitä."
      , usage =
            [ "primary brand"
            , "accent"
            ]
      }
    , { hex = "#05131D"
      , id = "lego-black"
      , name = "Black"
      , description = "Kaikki otsikot, leipäteksti ja navigaatio vaalealla taustalla. Käytä myös tummalle taustavärille."
      , usage =
            [ "features"
            , "text"
            , "dark background"
            ]
      }
    , { hex = "#FFFFFF"
      , id = "lego-white"
      , name = "White"
      , description = "Teksti ja kuvakkeet tummalla (Brand Black) taustalla. Sivun oletustaustaväri."
      , usage =
            [ "eye highlights"
            , "text on dark background"
            ]
      }
    , { hex = "#C91A09"
      , id = "red"
      , name = "Red"
      , description = "Aksentti- ja varoitusväri. Ei koskaan pääväri — käytä korostuksiin, danger-tiloihin ja graafisiin elementteihin."
      , usage =
            [ "accent"
            , "danger"
            , "highlights"
            ]
      }
    ]


{-| Minifig skin-tone palette.
-}
skinTones : List SkinToneEntry
skinTones =
    [ { hex = "#FAC80A"
      , id = "yellow"
      , name = "Yellow"
      , description = "Classic LEGO minifig yellow. Brand accent color."
      }
    , { hex = "#F6D7B3"
      , id = "light-nougat"
      , name = "Light Nougat"
      , description = "Light skin tone. Contrast on white: 1.4:1 — decorative only."
      }
    , { hex = "#D09168"
      , id = "nougat"
      , name = "Nougat"
      , description = "Medium skin tone. Contrast on black: 6.7:1 (AA)."
      }
    , { hex = "#AD6140"
      , id = "dark-nougat"
      , name = "Dark Nougat"
      , description = "Dark skin tone. Contrast on white: 4.4:1 (AA large text)."
      }
    ]


{-| Rainbow colour palette.
-}
rainbowColors : List RainbowColor
rainbowColors =
    [ { hex = "#F2705E"
      , name = "Salmon"
      , description = "Red"
      }
    , { hex = "#F9BA61"
      , name = "Light Orange"
      , description = "Orange"
      }
    , { hex = "#FAC80A"
      , name = "Yellow"
      , description = "Yellow"
      }
    , { hex = "#73DCA1"
      , name = "Medium Green"
      , description = "Green"
      }
    , { hex = "#9FC3E9"
      , name = "Bright Light Blue"
      , description = "Blue"
      }
    , { hex = "#9195CA"
      , name = "Light Lilac"
      , description = "Indigo"
      }
    , { hex = "#AC78BA"
      , name = "Medium Lavender"
      , description = "Violet"
      }
    ]
