module FinnishDate exposing (DateLocale, format, monthName, monthToInt, parse, weekdayAbbr)

{-| Date formatting and parsing for the date picker, in a given locale.

The locale is any record with the fields of `DateLocale`; `Locale.fi` from
the app toolkit is one.

@docs DateLocale, format, monthName, monthToInt, parse, weekdayAbbr

-}

import Date exposing (Date)
import Time exposing (Month(..), Weekday)


{-| The date conventions the picker needs from a locale.

  - `dateSeparator` — between day, month and year (`05.05.2025`).
  - `datePlaceholder` — hint shown in the empty input (`pp.kk.vvvv`).
  - `invalidDate` — message for a date that cannot be parsed.
  - `weekdayAbbr`, `monthName` — names shown in the calendar.
  - `firstDayOfWeek` — first column of the calendar.

-}
type alias DateLocale a =
    { a
        | dateSeparator : String
        , datePlaceholder : String
        , invalidDate : String
        , weekdayAbbr : Weekday -> String
        , monthName : Int -> String
        , firstDayOfWeek : Weekday
    }


{-| Formats a date in the locale's numerical format (`DD.MM.YYYY`).
-}
format : DateLocale a -> Date -> String
format locale date =
    pad2 (Date.day date)
        ++ locale.dateSeparator
        ++ pad2 (Date.monthNumber date)
        ++ locale.dateSeparator
        ++ String.fromInt (Date.year date)


{-| Parses a date string in the locale's format (`D.M.YYYY` or `DD.MM.YYYY`)
into a `Date`. Returns the locale's error message for invalid formats or
non-existent calendar dates.
-}
parse : DateLocale a -> String -> Result String Date
parse locale input =
    case String.split locale.dateSeparator (String.trim input) of
        [ dayStr, monthStr, yearStr ] ->
            case ( String.toInt dayStr, String.toInt monthStr, String.toInt yearStr ) of
                ( Just day, Just month, Just year ) ->
                    (String.fromInt year ++ "-" ++ pad2 month ++ "-" ++ pad2 day)
                        |> Date.fromIsoString
                        |> Result.mapError (\_ -> locale.invalidDate)

                _ ->
                    Err locale.invalidDate

        _ ->
            Err locale.invalidDate


{-| The locale's name of a month number (1–12), with a capital letter.
-}
monthName : DateLocale a -> Int -> String
monthName locale =
    locale.monthName


{-| Converts a `Time.Month` to its number (1–12).
-}
monthToInt : Month -> Int
monthToInt month =
    case month of
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


{-| The locale's weekday abbreviation.
-}
weekdayAbbr : DateLocale a -> Weekday -> String
weekdayAbbr locale =
    locale.weekdayAbbr


pad2 : Int -> String
pad2 n =
    String.padLeft 2 '0' (String.fromInt n)
