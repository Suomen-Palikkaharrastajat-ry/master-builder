module Frontmatter exposing (Frontmatter, decoder)

{-| Markdown front-matter type and JSON decoder.
-}

import Json.Decode as Decode exposing (Decoder)


type alias Frontmatter =
    { title : String
    , description : String
    , slug : String
    , published : Bool
    , nav : Bool
    }


decoder : Decoder Frontmatter
decoder =
    Decode.map5 Frontmatter
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "slug" Decode.string)
        (Decode.field "published" Decode.bool)
        (Decode.oneOf [ Decode.field "nav" Decode.bool, Decode.succeed False ])
