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
        |> String.toList
        |> List.map transliterateChar
        |> String.concat
        |> String.map
            (\c ->
                if Char.isAlphaNum c then
                    c

                else
                    '-'
            )
        |> String.split "-"
        |> List.filter (not << String.isEmpty)
        |> String.join "-"


transliterateChar : Char -> String
transliterateChar char =
    case char of
        'ß' ->
            "ss"

        'æ' ->
            "ae"

        'œ' ->
            "oe"

        'þ' ->
            "th"

        _ ->
            String.fromChar (deaccentChar char)


deaccentChar : Char -> Char
deaccentChar char =
    case char of
        'à' ->
            'a'

        'á' ->
            'a'

        'â' ->
            'a'

        'ã' ->
            'a'

        'ä' ->
            'a'

        'å' ->
            'a'

        'ā' ->
            'a'

        'ă' ->
            'a'

        'ą' ->
            'a'

        'ç' ->
            'c'

        'ć' ->
            'c'

        'ĉ' ->
            'c'

        'ċ' ->
            'c'

        'č' ->
            'c'

        'ď' ->
            'd'

        'đ' ->
            'd'

        'è' ->
            'e'

        'é' ->
            'e'

        'ê' ->
            'e'

        'ë' ->
            'e'

        'ē' ->
            'e'

        'ĕ' ->
            'e'

        'ė' ->
            'e'

        'ę' ->
            'e'

        'ě' ->
            'e'

        'ĝ' ->
            'g'

        'ğ' ->
            'g'

        'ġ' ->
            'g'

        'ģ' ->
            'g'

        'ĥ' ->
            'h'

        'ħ' ->
            'h'

        'ì' ->
            'i'

        'í' ->
            'i'

        'î' ->
            'i'

        'ï' ->
            'i'

        'ĩ' ->
            'i'

        'ī' ->
            'i'

        'ĭ' ->
            'i'

        'į' ->
            'i'

        'ı' ->
            'i'

        'ĵ' ->
            'j'

        'ķ' ->
            'k'

        'ĺ' ->
            'l'

        'ļ' ->
            'l'

        'ľ' ->
            'l'

        'ŀ' ->
            'l'

        'ł' ->
            'l'

        'ñ' ->
            'n'

        'ń' ->
            'n'

        'ņ' ->
            'n'

        'ň' ->
            'n'

        'ò' ->
            'o'

        'ó' ->
            'o'

        'ô' ->
            'o'

        'õ' ->
            'o'

        'ö' ->
            'o'

        'ø' ->
            'o'

        'ō' ->
            'o'

        'ŏ' ->
            'o'

        'ő' ->
            'o'

        'ŕ' ->
            'r'

        'ŗ' ->
            'r'

        'ř' ->
            'r'

        'ś' ->
            's'

        'ŝ' ->
            's'

        'ş' ->
            's'

        'š' ->
            's'

        'ţ' ->
            't'

        'ť' ->
            't'

        'ŧ' ->
            't'

        'ù' ->
            'u'

        'ú' ->
            'u'

        'û' ->
            'u'

        'ü' ->
            'u'

        'ũ' ->
            'u'

        'ū' ->
            'u'

        'ŭ' ->
            'u'

        'ů' ->
            'u'

        'ű' ->
            'u'

        'ų' ->
            'u'

        'ŵ' ->
            'w'

        'ý' ->
            'y'

        'ÿ' ->
            'y'

        'ŷ' ->
            'y'

        'ź' ->
            'z'

        'ż' ->
            'z'

        'ž' ->
            'z'

        _ ->
            char


externalLinkAttrs : String -> List (Attribute msg)
externalLinkAttrs destination =
    if String.startsWith "http://" destination || String.startsWith "https://" destination then
        [ Attr.target "_blank", Attr.rel "noopener noreferrer" ]

    else
        []
