module Lang exposing
    ( Lang(..), all, fromString, toString
    , switchQuery, isSwitch, attributeFor
    )

{-| The languages a family site can be shown in.

Every site is language-aware even when it ships a single language: views take
a `Lang` (or strings resolved for one) instead of containing display text.

@docs Lang, all, fromString, toString
@docs switchQuery, isSwitch, attributeFor

-}

import Html
import Html.Attributes


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


{-| The link target that switches a site to a language (`?lang=en`). The
language is read when the page starts, so following the link has to load the
page; see `isSwitch`.
-}
switchQuery : Lang -> String
switchQuery lang =
    "?lang=" ++ toString lang


{-| Whether a URL's query asks for another language than the current one. An
app that handles its own link clicks calls this with its language and
`url.query`, and loads the page instead of routing when it is `True`.
-}
isSwitch : Lang -> Maybe String -> Bool
isSwitch current query =
    query
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.filterMap
            (\parameter ->
                if String.startsWith "lang=" parameter then
                    fromString (String.dropLeft 5 parameter)

                else
                    Nothing
            )
        |> List.any (\requested -> requested /= current)


{-| The `lang` attribute for content written in another language than the
interface around it — events entered in Finnish inside an English page — so
that screen readers pronounce it correctly (WCAG 3.1.2). Empty when the two are
the same.
-}
attributeFor : { interface : Lang, content : Lang } -> List (Html.Attribute msg)
attributeFor { interface, content } =
    if interface == content then
        []

    else
        [ Html.Attributes.lang (toString content) ]
