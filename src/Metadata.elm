module Metadata exposing
    ( absoluteUrl
    , maybeMetaName
    , pageCanonicalUrl
    , socialImage
    , webPageStructuredData
    , websiteStructuredData
    )

{-| Shared helpers for SEO metadata, social images, and structured data.
-}

import Head
import Head.Seo as Seo
import Json.Encode as Encode
import MimeType
import Pages.Url
import String


{-| Join a site URL and path into an absolute URL. Absolute URLs are passed through unchanged.
-}
absoluteUrl : String -> String -> String
absoluteUrl siteUrl path =
    if String.startsWith "https://" path || String.startsWith "http://" path then
        path

    else
        trimTrailingSlashes siteUrl
            ++ "/"
            ++ trimLeadingSlashes path


trimLeadingSlashes : String -> String
trimLeadingSlashes value =
    if String.startsWith "/" value then
        trimLeadingSlashes (String.dropLeft 1 value)

    else
        value


trimTrailingSlashes : String -> String
trimTrailingSlashes value =
    if String.endsWith "/" value then
        trimTrailingSlashes (String.dropRight 1 value)

    else
        value


{-| Resolve the canonical URL for a route from the site URL and route path.
-}
pageCanonicalUrl : String -> String -> String
pageCanonicalUrl siteUrl path =
    absoluteUrl siteUrl path


{-| Resolve a frontmatter image path or fall back to the default social image.
-}
socialImage :
    { defaultImageAlt : String
    , defaultImagePath : String
    , maybeImageAlt : Maybe String
    , maybeImagePath : Maybe String
    , siteUrl : String
    }
    -> Seo.Image
socialImage config =
    let
        resolvedPath : String
        resolvedPath =
            Maybe.withDefault config.defaultImagePath config.maybeImagePath

        resolvedAlt : String
        resolvedAlt =
            Maybe.withDefault config.defaultImageAlt config.maybeImageAlt

        isDefaultImage : Bool
        isDefaultImage =
            resolvedPath
                == config.defaultImagePath
                || absoluteUrl config.siteUrl resolvedPath
                == absoluteUrl config.siteUrl config.defaultImagePath
    in
    { url = Pages.Url.external (absoluteUrl config.siteUrl resolvedPath)
    , alt = resolvedAlt
    , dimensions =
        if isDefaultImage then
            Just { width = 1200, height = 630 }

        else
            Nothing
    , mimeType =
        if isDefaultImage then
            Just (MimeType.Image MimeType.Png)

        else
            Nothing
    }


{-| Render a meta tag only when the value is present.
-}
maybeMetaName : String -> Maybe String -> List Head.Tag
maybeMetaName name maybeValue =
    case maybeValue of
        Just value ->
            [ Head.metaName name (Head.raw value) ]

        Nothing ->
            []


{-| Structured data for the website as a whole and its publisher organization.
-}
websiteStructuredData :
    { description : String
    , logoPath : String
    , name : String
    , url : String
    }
    -> List Head.Tag
websiteStructuredData site =
    [ Encode.object
        [ ( "@context", Encode.string "https://schema.org" )
        , ( "@type", Encode.string "WebSite" )
        , ( "name", Encode.string site.name )
        , ( "description", Encode.string site.description )
        , ( "url", Encode.string site.url )
        ]
        |> Head.structuredData
    , Encode.object
        [ ( "@context", Encode.string "https://schema.org" )
        , ( "@type", Encode.string "Organization" )
        , ( "name", Encode.string site.name )
        , ( "url", Encode.string site.url )
        , ( "logo", Encode.string (absoluteUrl site.url site.logoPath) )
        ]
        |> Head.structuredData
    ]


{-| Structured data for an individual page.
-}
webPageStructuredData :
    { description : String
    , title : String
    , url : String
    }
    -> Head.Tag
webPageStructuredData page =
    Encode.object
        [ ( "@context", Encode.string "https://schema.org" )
        , ( "@type", Encode.string "WebPage" )
        , ( "name", Encode.string page.title )
        , ( "description", Encode.string page.description )
        , ( "url", Encode.string page.url )
        ]
        |> Head.structuredData
