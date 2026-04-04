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


type alias Frontmatter =
    { title : String
    , description : String
    , slug : String
    , published : Bool
    , nav : NavVisibility
    , navTitle : Maybe String
    , order : Int
    , image : Maybe String
    }


decoder : Decoder Frontmatter
decoder =
    Decode.map8 Frontmatter
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "published" Decode.bool)
        (Decode.oneOf
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
        )
        (Decode.maybe (Decode.field "navTitle" Decode.string))
        (Decode.oneOf [ Decode.field "order" Decode.int, Decode.succeed 999 ])
        (Decode.maybe (Decode.field "image" Decode.string))
