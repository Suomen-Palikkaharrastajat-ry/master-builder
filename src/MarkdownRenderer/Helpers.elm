module MarkdownRenderer.Helpers exposing (HeadingItem, decodeHtmlEntities, externalLinkAttrs, headingSlug, normalizeSrc, splitClassPrefix)

{-| Shared helpers for markdown rendering.
-}

import Html exposing (Attribute)
import Html.Attributes as Attr
import Regex


type alias HeadingItem =
    { level : Int
    , text : String
    , id : String
    }


splitClassPrefix : String -> ( Maybe String, String )
splitClassPrefix str =
    case Regex.fromString "^\\{([^}]*)\\}\\s*(.*)$" of
        Nothing ->
            ( Nothing, str )

        Just re ->
            case Regex.find re str of
                [] ->
                    ( Nothing, str )

                match :: _ ->
                    case match.submatches of
                        [ maybeCls, maybeRest ] ->
                            let
                                rest =
                                    Maybe.withDefault "" maybeRest
                            in
                            ( maybeCls, rest )

                        _ ->
                            ( Nothing, str )


normalizeSrc : String -> String -> String
normalizeSrc pageDir src =
    if
        String.startsWith "http://" src
            || String.startsWith "https://" src
            || String.startsWith "/" src
            || String.startsWith "data:" src
    then
        src

    else if String.startsWith "./" src then
        "/" ++ pageDir ++ String.dropLeft 2 src

    else
        "/" ++ pageDir ++ src


decodeHtmlEntities : String -> String
decodeHtmlEntities raw =
    raw
        |> String.replace "&lt;" "<"
        |> String.replace "&gt;" ">"
        |> String.replace "&amp;" "&"


headingSlug : String -> String
headingSlug text =
    text
        |> String.toLower
        |> String.map (\c -> if Char.isAlphaNum c then c else '-')
        |> String.split "-"
        |> List.filter (not << String.isEmpty)
        |> String.join "-"


externalLinkAttrs : String -> List (Attribute msg)
externalLinkAttrs destination =
    if String.startsWith "http://" destination || String.startsWith "https://" destination then
        [ Attr.target "_blank", Attr.rel "noopener noreferrer" ]

    else
        []
