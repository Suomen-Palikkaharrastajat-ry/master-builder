module DesignTokens.Metadata exposing
    ( organization
    , siteName
    , siteShortName
    , defaultTitle
    , defaultDescription
    , canonicalUrl
    , defaultLocale
    , robots
    , author
    , themeColor
    , colorScheme
    , formatDetection
    , ogType
    , twitterCard
    , applicationName
    , appleMobileWebAppTitle
    , appleMobileWebAppCapable
    , appleMobileWebAppStatusBarStyle
    , mobileWebAppCapable
    , manifestUrl
    , manifestStartUrl
    , manifestDisplay
    , manifestBackgroundColor
    , manifestThemeColor
    , schemaType
    )


{-| Site metadata tokens for SEO, social sharing, and PWA manifests. -}

{-| Organization name. -}
organization : String
organization =
    "Suomen Palikkaharrastajat ry"

{-| Site name for SEO and Open Graph. -}
siteName : String
siteName =
    "Suomen Palikkaharrastajat"

{-| Short site name for app and icon contexts. -}
siteShortName : String
siteShortName =
    "Palikkaharrastajat"

{-| Default page title. -}
defaultTitle : String
defaultTitle =
    "Suomen Palikkaharrastajat"

{-| Default page description. -}
defaultDescription : String
defaultDescription =
    "Suomen Palikkaharrastajat ry on suomalainen LEGO-harrastajayhdistys, joka kokoaa harrastajat yhteen tapahtumiin, yhteisöön ja inspiroivaan rakenteluun."

{-| Canonical site URL. -}
canonicalUrl : String
canonicalUrl =
    "https://palikkaharrastajat.fi"

{-| Default site locale. -}
defaultLocale : String
defaultLocale =
    "fi_FI"

{-| Robots directive. -}
robots : String
robots =
    "index, follow"

{-| Author metadata. -}
author : String
author =
    "Suomen Palikkaharrastajat ry"

{-| Browser theme color. -}
themeColor : String
themeColor =
    "#05131D"

{-| Supported browser color schemes. -}
colorScheme : String
colorScheme =
    "light dark"

{-| Browser auto-link detection directive. -}
formatDetection : String
formatDetection =
    "telephone=no"

{-| Open Graph object type. -}
ogType : String
ogType =
    "website"

{-| Twitter card type. -}
twitterCard : String
twitterCard =
    "summary_large_image"

{-| Installable application name. -}
applicationName : String
applicationName =
    "Suomen Palikkaharrastajat"

{-| iOS app title. -}
appleMobileWebAppTitle : String
appleMobileWebAppTitle =
    "Palikkaharrastajat"

{-| Enable standalone iOS web app mode. -}
appleMobileWebAppCapable : Bool
appleMobileWebAppCapable =
    True

{-| iOS status bar style. -}
appleMobileWebAppStatusBarStyle : String
appleMobileWebAppStatusBarStyle =
    "default"

{-| Enable standalone Android web app mode. -}
mobileWebAppCapable : Bool
mobileWebAppCapable =
    True

{-| Web app manifest path. -}
manifestUrl : String
manifestUrl =
    "/site.webmanifest"

{-| Manifest start URL. -}
manifestStartUrl : String
manifestStartUrl =
    "/"

{-| Manifest display mode. -}
manifestDisplay : String
manifestDisplay =
    "standalone"

{-| Manifest background color. -}
manifestBackgroundColor : String
manifestBackgroundColor =
    "#FFFFFF"

{-| Manifest theme color. -}
manifestThemeColor : String
manifestThemeColor =
    "#05131D"

{-| schema.org type for JSON-LD. -}
schemaType : String
schemaType =
    "WebSite"
