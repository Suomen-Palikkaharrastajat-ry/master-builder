module Frontmatter exposing (Frontmatter, NavVisibility(..), decoder)

{-| Markdown front-matter type and JSON decoder.
-}

import Json.Decode as Decode exposing (Decoder)


{-| Controls where a page appears in navigation.

  - `NavAll` — visible in both desktop and mobile nav (`nav: true`)
  - `NavMobileOnly` — visible in mobile drawer only (`nav: mobile`)
  - `NavHidden` — not shown in any nav (`nav: false` or absent)

-}
type NavVisibility
    = NavAll
    | NavMobileOnly
    | NavHidden


{-| Content-level metadata loaded from each Markdown file's YAML frontmatter.

These fields are used in three main places:

  - route data loading in [`Route.Index`], [`Route.Slug_`], and [`Route.Blog.Slug_`]
  - navigation building in [`Shared.navItemsTask`]
  - page head metadata generation in the route `head` functions

Field usage:

  - `title` renders the page title in views and is also used for Open Graph and Twitter titles
  - `description` is used for the page meta description and for Open Graph and Twitter descriptions
  - `slug` is used by [`Shared.navItemsTask`] to build internal navigation links
  - `published` controls whether the page is built and appears in navigation and TOC; defaults to `True` when absent
  - `nav` controls whether the page appears in desktop/mobile navigation
  - `navTitle` overrides the navigation label while leaving the page title unchanged
  - `order` sorts items in the navigation
  - `image` overrides the default social sharing image for Open Graph and Twitter cards
  - `imageAlt` provides alt text for the social sharing image
  - `author` overrides the site-wide author meta tag for this page
  - `robots` overrides the site-wide robots meta tag for this page (e.g. `noindex, nofollow`)

-}
type alias Frontmatter =
    { title : String
    , description : String
    , slug : String
    , published : Bool
    , nav : NavVisibility
    , navTitle : Maybe String
    , order : Int
    , image : Maybe String
    , imageAlt : Maybe String
    , author : Maybe String
    , robots : Maybe String
    }


decoder : Decoder Frontmatter
decoder =
    Decode.succeed Frontmatter
        |> andMap (Decode.field "title" Decode.string)
        |> andMap (Decode.field "description" Decode.string)
        |> andMap (Decode.field "slug" Decode.string)
        |> andMap (Decode.oneOf [ Decode.field "published" Decode.bool, Decode.succeed True ])
        |> andMap navDecoder
        |> andMap (Decode.maybe (Decode.field "navTitle" Decode.string))
        |> andMap (Decode.oneOf [ Decode.field "order" Decode.int, Decode.succeed 999 ])
        |> andMap (Decode.maybe (Decode.field "image" Decode.string))
        |> andMap (Decode.maybe (Decode.field "imageAlt" Decode.string))
        |> andMap (Decode.maybe (Decode.field "author" Decode.string))
        |> andMap (Decode.maybe (Decode.field "robots" Decode.string))


navDecoder : Decoder NavVisibility
navDecoder =
    Decode.oneOf
        [ Decode.field "nav" Decode.bool
            |> Decode.map
                (\b ->
                    if b then
                        NavAll

                    else
                        NavHidden
                )
        , Decode.field "nav" Decode.string
            |> Decode.map
                (\s ->
                    if s == "mobile" then
                        NavMobileOnly

                    else
                        NavHidden
                )
        , Decode.succeed NavHidden
        ]


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap valueDecoder functionDecoder =
    Decode.map2 (\fn value -> fn value) functionDecoder valueDecoder
