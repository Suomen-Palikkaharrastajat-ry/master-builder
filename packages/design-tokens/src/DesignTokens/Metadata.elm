module DesignTokens.Metadata exposing
    ( brandGuideUrl
    , ogType
    , schemaType
    , featureColor
    , highlightColor
    , darkBg
    , subtitleOnLight
    , subtitleOnDark
    , headSvgFaceColor
    )


{-| Design-guide-specific metadata tokens. Site metadata (title, locale, PWA settings, etc.) lives in config.toml. -}

{-| Brand guide URL. -}
brandGuideUrl : String
brandGuideUrl =
    "https://logo.palikkaharrastajat.fi"

{-| Open Graph object type. -}
ogType : String
ogType =
    "website"

{-| schema.org type for JSON-LD. -}
schemaType : String
schemaType =
    "WebSite"

{-| Feature highlight color (hex). -}
featureColor : String
featureColor =
    "#05131D"

{-| Highlight / on-dark accent color (hex). -}
highlightColor : String
highlightColor =
    "#FFFFFF"

{-| Dark background color (hex). -}
darkBg : String
darkBg =
    "#05131D"

{-| Subtitle color on light surface (hex). -}
subtitleOnLight : String
subtitleOnLight =
    "#05131D"

{-| Subtitle color on dark surface (hex). -}
subtitleOnDark : String
subtitleOnDark =
    "#FFFFFF"

{-| Head SVG face fill color (hex). -}
headSvgFaceColor : String
headSvgFaceColor =
    "#f8c70b"
