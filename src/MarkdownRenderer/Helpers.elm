module MarkdownRenderer.Helpers exposing (decodeHtmlEntities, externalLinkAttrs, normalizeSrc, splitClassPrefix, splitImageDirectives)

{-| Shared helpers for markdown rendering.
-}

import Html exposing (Attribute)
import Html.Attributes as Attr
import Regex


splitImageDirectives : String -> ( List String, String )
splitImageDirectives str =
    let
        ( maybeClass, altText ) =
            splitClassPrefix str
    in
    case maybeClass of
        Nothing ->
            ( [], altText )

        Just "" ->
            ( [], altText )

        Just cls ->
            ( String.words cls, altText )


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


normalizeSrc : String -> String
normalizeSrc src =
    if
        String.startsWith "http://" src
            || String.startsWith "https://" src
            || String.startsWith "/" src
            || String.startsWith "data:" src
    then
        src

    else if String.startsWith "./" src then
        "/" ++ String.dropLeft 2 src

    else
        "/" ++ src


decodeHtmlEntities : String -> String
decodeHtmlEntities raw =
    raw
        |> String.replace "&lt;" "<"
        |> String.replace "&gt;" ">"
        |> String.replace "&amp;" "&"


externalLinkAttrs : String -> List (Attribute msg)
externalLinkAttrs destination =
    if String.startsWith "http://" destination || String.startsWith "https://" destination then
        [ Attr.target "_blank", Attr.rel "noopener noreferrer" ]

    else
        []
