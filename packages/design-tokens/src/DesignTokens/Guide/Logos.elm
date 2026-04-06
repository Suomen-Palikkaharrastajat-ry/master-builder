module DesignTokens.Guide.Logos exposing
    ( LogoVariant
    , SocialImage
    , WebIcon
    , horizontalVariants
    , socialImages
    , squareFullVariants
    , squareVariants
    , webIcons
    )

{-| Structured logo variant data for brand guide pages.

Use these lists to render logo galleries and download links.

-}


{-| One downloadable logo variant with all its rendering properties.
-}
type alias LogoVariant =
    { id : String
    , description : String
    , theme : String
    , animated : Bool
    , withText : Bool
    , bold : Bool
    , highlight : Bool
    , svgUrl : Maybe String
    , pngUrl : Maybe String
    , webpUrl : Maybe String
    , gifUrl : Maybe String
    }


{-| Default social sharing image metadata.
-}
type alias SocialImage =
    { id : String
    , description : String
    , url : String
    , absoluteUrl : String
    , alt : String
    , width : Int
    , height : Int
    , mimeType : String
    , platforms : List String
    }


{-| Web icon and install asset metadata.
-}
type alias WebIcon =
    { id : String
    , description : String
    , rel : String
    , url : String
    , mimeType : String
    , sizes : List String
    , purpose : List String
    , platforms : List String
    }


{-| Square (icon-only) logo variants.
-}
squareVariants : List LogoVariant
squareVariants =
    [ { id = "square-basic"
      , description = "Neutraali ilme"
      , theme = "light"
      , animated = False
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-basic.svg"
      , pngUrl = Just "/logo/square/png/square-basic.png"
      , webpUrl = Just "/logo/square/png/square-basic.webp"
      , gifUrl = Nothing
      }
    , { id = "square-smile"
      , description = "Hymyilevä ilme"
      , theme = "light"
      , animated = False
      , withText = False
      , bold = False
      , highlight = True
      , svgUrl = Just "/logo/square/svg/square-smile.svg"
      , pngUrl = Just "/logo/square/png/square-smile.png"
      , webpUrl = Just "/logo/square/png/square-smile.webp"
      , gifUrl = Nothing
      }
    , { id = "square-blink"
      , description = "Silmää iskevä ilme"
      , theme = "light"
      , animated = False
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-blink.svg"
      , pngUrl = Just "/logo/square/png/square-blink.png"
      , webpUrl = Just "/logo/square/png/square-blink.webp"
      , gifUrl = Nothing
      }
    , { id = "square-laugh"
      , description = "Naurava ilme"
      , theme = "light"
      , animated = False
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-laugh.svg"
      , pngUrl = Just "/logo/square/png/square-laugh.png"
      , webpUrl = Just "/logo/square/png/square-laugh.webp"
      , gifUrl = Nothing
      }
    , { id = "square-animated"
      , description = "Animoitu logo, käy läpi kaikki neljä ilmettä"
      , theme = "light"
      , animated = True
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/square/png/square-animated.webp"
      , gifUrl = Just "/logo/square/png/square-animated.gif"
      }
    ]


{-| Square logo variants with two-line text.
-}
squareFullVariants : List LogoVariant
squareFullVariants =
    [ { id = "square-smile-full"
      , description = "Hymyilevä logo kahdella tekstirivillä, vaalea teema"
      , theme = "light"
      , animated = False
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-smile-full.svg"
      , pngUrl = Just "/logo/square/png/square-smile-full.png"
      , webpUrl = Just "/logo/square/png/square-smile-full.webp"
      , gifUrl = Nothing
      }
    , { id = "square-smile-full-bold"
      , description = "Hymyilevä logo kahdella tekstirivillä, lihavoitu, vaalea teema"
      , theme = "light"
      , animated = False
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-smile-full-bold.svg"
      , pngUrl = Just "/logo/square/png/square-smile-full-bold.png"
      , webpUrl = Just "/logo/square/png/square-smile-full-bold.webp"
      , gifUrl = Nothing
      }
    , { id = "square-smile-full-dark"
      , description = "Hymyilevä logo kahdella tekstirivillä, tumma teema"
      , theme = "dark"
      , animated = False
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-smile-full-dark.svg"
      , pngUrl = Just "/logo/square/png/square-smile-full-dark.png"
      , webpUrl = Just "/logo/square/png/square-smile-full-dark.webp"
      , gifUrl = Nothing
      }
    , { id = "square-smile-full-dark-bold"
      , description = "Hymyilevä logo kahdella tekstirivillä, lihavoitu, tumma teema"
      , theme = "dark"
      , animated = False
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Just "/logo/square/svg/square-smile-full-dark-bold.svg"
      , pngUrl = Just "/logo/square/png/square-smile-full-dark-bold.png"
      , webpUrl = Just "/logo/square/png/square-smile-full-dark-bold.webp"
      , gifUrl = Nothing
      }
    ]


{-| Horizontal logo variants.
-}
horizontalVariants : List LogoVariant
horizontalVariants =
    [ { id = "horizontal"
      , description = "Pelkkä logo, vaalea teema"
      , theme = "light"
      , animated = False
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/horizontal/svg/horizontal.svg"
      , pngUrl = Just "/logo/horizontal/png/horizontal.png"
      , webpUrl = Just "/logo/horizontal/png/horizontal.webp"
      , gifUrl = Nothing
      }
    , { id = "horizontal-full"
      , description = "Logo yhdistyksen nimellä, vaalea teema"
      , theme = "light"
      , animated = False
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/horizontal/svg/horizontal-full.svg"
      , pngUrl = Just "/logo/horizontal/png/horizontal-full.png"
      , webpUrl = Just "/logo/horizontal/png/horizontal-full.webp"
      , gifUrl = Nothing
      }
    , { id = "horizontal-full-bold"
      , description = "Logo nimitekstillä, lihavoitu, vaalea teema"
      , theme = "light"
      , animated = False
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Just "/logo/horizontal/svg/horizontal-full-bold.svg"
      , pngUrl = Just "/logo/horizontal/png/horizontal-full-bold.png"
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-bold.webp"
      , gifUrl = Nothing
      }
    , { id = "horizontal-full-dark"
      , description = "Logo nimitekstillä, tumma teema"
      , theme = "dark"
      , animated = False
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Just "/logo/horizontal/svg/horizontal-full-dark.svg"
      , pngUrl = Just "/logo/horizontal/png/horizontal-full-dark.png"
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-dark.webp"
      , gifUrl = Nothing
      }
    , { id = "horizontal-full-dark-bold"
      , description = "Logo nimitekstillä, lihavoitu, tumma teema"
      , theme = "dark"
      , animated = False
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Just "/logo/horizontal/svg/horizontal-full-dark-bold.svg"
      , pngUrl = Just "/logo/horizontal/png/horizontal-full-dark-bold.png"
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-dark-bold.webp"
      , gifUrl = Nothing
      }
    , { id = "horizontal-animated"
      , description = "Animoitu logo"
      , theme = "light"
      , animated = True
      , withText = False
      , bold = False
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/horizontal/png/horizontal-animated.webp"
      , gifUrl = Just "/logo/horizontal/png/horizontal-animated.gif"
      }
    , { id = "horizontal-full-animated"
      , description = "Animoitu logo nimitekstillä, vaalea teema"
      , theme = "light"
      , animated = True
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-animated.webp"
      , gifUrl = Just "/logo/horizontal/png/horizontal-full-animated.gif"
      }
    , { id = "horizontal-full-bold-animated"
      , description = "Animoitu logo nimitekstillä, lihavoitu, vaalea teema"
      , theme = "light"
      , animated = True
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-bold-animated.webp"
      , gifUrl = Just "/logo/horizontal/png/horizontal-full-bold-animated.gif"
      }
    , { id = "horizontal-full-dark-animated"
      , description = "Animoitu logo nimitekstillä, tumma teema"
      , theme = "dark"
      , animated = True
      , withText = True
      , bold = False
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-dark-animated.webp"
      , gifUrl = Just "/logo/horizontal/png/horizontal-full-dark-animated.gif"
      }
    , { id = "horizontal-full-dark-bold-animated"
      , description = "Animoitu logo nimitekstillä, lihavoitu, tumma teema"
      , theme = "dark"
      , animated = True
      , withText = True
      , bold = True
      , highlight = False
      , svgUrl = Nothing
      , pngUrl = Nothing
      , webpUrl = Just "/logo/horizontal/png/horizontal-full-dark-bold-animated.webp"
      , gifUrl = Just "/logo/horizontal/png/horizontal-full-dark-bold-animated.gif"
      }
    ]


{-| Default social sharing images for Open Graph and Twitter.
-}
socialImages : List SocialImage
socialImages =
    [ { id = "open-graph-default"
      , description = "Oletuskuva Open Graph- ja Twitter-kortteihin."
      , url = "/og-image.jpg"
      , absoluteUrl = "https://palikkaharrastajat.fi/og-image.jpg"
      , alt = "Suomen Palikkaharrastajat ry:n Open Graph -jakokuva."
      , width = 1200
      , height = 630
      , mimeType = "image/jpeg"
      , platforms =
            [ "open-graph"
            , "twitter"
            ]
      }
    ]


{-| Favicon, touch icon, and install icon assets.
-}
webIcons : List WebIcon
webIcons =
    [ { id = "favicon-ico"
      , description = "Perinteinen favicon laajaa selainyhteensopivuutta varten."
      , rel = "icon"
      , url = "/favicon.ico"
      , mimeType = "image/x-icon"
      , sizes =
            [ "16x16"
            , "32x32"
            , "48x48"
            ]
      , purpose = []
      , platforms = [ "browser" ]
      }
    , { id = "favicon-svg"
      , description = "Skaalautuva SVG-favicon moderneille selaimille."
      , rel = "icon"
      , url = "/favicon.svg"
      , mimeType = "image/svg+xml"
      , sizes = [ "any" ]
      , purpose = []
      , platforms = [ "browser" ]
      }
    , { id = "favicon-16"
      , description = "PNG-favicon 16x16-kokoisena."
      , rel = "icon"
      , url = "/favicon-16x16.png"
      , mimeType = "image/png"
      , sizes = [ "16x16" ]
      , purpose = []
      , platforms = [ "browser" ]
      }
    , { id = "favicon-32"
      , description = "PNG-favicon 32x32-kokoisena."
      , rel = "icon"
      , url = "/favicon-32x32.png"
      , mimeType = "image/png"
      , sizes = [ "32x32" ]
      , purpose = []
      , platforms = [ "browser" ]
      }
    , { id = "favicon-48"
      , description = "PNG-favicon 48x48-kokoisena."
      , rel = "icon"
      , url = "/favicon-48x48.png"
      , mimeType = "image/png"
      , sizes = [ "48x48" ]
      , purpose = []
      , platforms = [ "browser" ]
      }
    , { id = "apple-touch-icon"
      , description = "Apple touch -ikoni iOS-kotiruutua varten."
      , rel = "apple-touch-icon"
      , url = "/apple-touch-icon.png"
      , mimeType = "image/png"
      , sizes = [ "180x180" ]
      , purpose = []
      , platforms =
            [ "ios"
            , "safari"
            ]
      }
    , { id = "android-chrome-192"
      , description = "Android- ja PWA-asennusikoni 192x192-kokoisena."
      , rel = "icon"
      , url = "/android-chrome-192x192.png"
      , mimeType = "image/png"
      , sizes = [ "192x192" ]
      , purpose = []
      , platforms =
            [ "android"
            , "chrome"
            , "pwa"
            ]
      }
    , { id = "android-chrome-512"
      , description = "Android- ja PWA-asennusikoni 512x512-kokoisena."
      , rel = "icon"
      , url = "/android-chrome-512x512.png"
      , mimeType = "image/png"
      , sizes = [ "512x512" ]
      , purpose = []
      , platforms =
            [ "android"
            , "chrome"
            , "pwa"
            ]
      }
    , { id = "icon-maskable"
      , description = "Maskable-ikoni Androidille ja PWA-asennuksiin."
      , rel = "icon"
      , url = "/icon-maskable.png"
      , mimeType = "image/png"
      , sizes = [ "512x512" ]
      , purpose = [ "maskable" ]
      , platforms =
            [ "android"
            , "chrome"
            , "pwa"
            ]
      }
    ]
