module FinnishDate exposing (format, monthName, monthToInt, parse, weekdayAbbr)

{-| Finnish date localization and formatting helpers.

@docs format, monthName, monthToInt, parse, weekdayAbbr

-}

import Date exposing (Date)
import Time exposing (Month(..), Weekday(..))


{-| Formats a date in Finnish numerical format (`DD.MM.YYYY`).
-}
format : Date -> String
format date =
    pad2 (Date.day date)
        ++ "."
        ++ pad2 (Date.monthNumber date)
        ++ "."
        ++ String.fromInt (Date.year date)


{-| Parses a Finnish date string (`D.M.YYYY` or `DD.MM.YYYY`) into a `Date`.
Returns an `Err` message for invalid formats or non-existent calendar dates.
-}
parse : String -> Result String Date
parse finnishDate =
    let
        trimmed =
            String.trim finnishDate
    in
    case String.split "." trimmed of
        [ dayStr, monthStr, yearStr ] ->
            case ( String.toInt dayStr, String.toInt monthStr, String.toInt yearStr ) of
                ( Just day, Just month, Just year ) ->
                    let
                        isoCandidate =
                            String.fromInt year
                                ++ "-"
                                ++ pad2 month
                                ++ "-"
                                ++ pad2 day
                    in
                    Date.fromIsoString isoCandidate
                        |> Result.mapError (\_ -> "Virheellinen päivämäärä")

                _ ->
                    Err "Virheellinen päivämäärä"

        _ ->
            Err "Virheellinen päivämäärä"


{-| Converts a month number (1–12) to its Finnish name with a capital letter.
-}
monthName : Int -> String
monthName m =
    case m of
        1 ->
            "Tammikuu"

        2 ->
            "Helmikuu"

        3 ->
            "Maaliskuu"

        4 ->
            "Huhtikuu"

        5 ->
            "Toukokuu"

        6 ->
            "Kesäkuu"

        7 ->
            "Heinäkuu"

        8 ->
            "Elokuu"

        9 ->
            "Syyskuu"

        10 ->
            "Lokakuu"

        11 ->
            "Marraskuu"

        12 ->
            "Joulukuu"

        _ ->
            ""


{-| Converts a `Time.Month` to its 1-based index (1–12).
-}
monthToInt : Month -> Int
monthToInt m =
    case m of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


{-| Returns the standard 2-letter Finnish weekday abbreviation.
-}
weekdayAbbr : Weekday -> String
weekdayAbbr w =
    case w of
        Mon ->
            "ma"

        Tue ->
            "ti"

        Wed ->
            "ke"

        Thu ->
            "to"

        Fri ->
            "pe"

        Sat ->
            "la"

        Sun ->
            "su"


pad2 : Int -> String
pad2 n =
    String.padLeft 2 '0' (String.fromInt n)
