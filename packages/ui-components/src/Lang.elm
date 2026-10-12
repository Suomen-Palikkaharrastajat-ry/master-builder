module Lang exposing (Lang(..), all, fromString, toString)

{-| The languages a family site can be shown in.

Every site is language-aware even when it ships a single language: views take
a `Lang` (or strings resolved for one) instead of containing display text.

@docs Lang, all, fromString, toString

-}


{-| A supported language.
-}
type Lang
    = Fi
    | En


{-| Every supported language.
-}
all : List Lang
all =
    [ Fi, En ]


{-| Two-letter code, as used in `config.toml` and the `lang` attribute.
-}
toString : Lang -> String
toString lang =
    case lang of
        Fi ->
            "fi"

        En ->
            "en"


{-| Parses a two-letter code; a longer tag such as `en-GB` matches on its prefix.
-}
fromString : String -> Maybe Lang
fromString code =
    case String.left 2 (String.toLower code) of
        "fi" ->
            Just Fi

        "en" ->
            Just En

        _ ->
            Nothing
