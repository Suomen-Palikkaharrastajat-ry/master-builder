module Locale exposing (Locale, en, fi, forCode)

{-| How dates and times are written in a language.

The date and time helpers take a `Locale` instead of assuming Finnish, so
Finnish is one localisation among others even on a Finnish-only site. The
time zone is not part of it: every site shows Helsinki time.

@docs Locale, en, fi, forCode

-}

import Time exposing (Weekday(..))


{-| A language's date and time conventions.

  - `code` — two-letter language code.
  - `weekdayAbbr`, `monthName` — names for calendars and headings.
  - `dateSeparator` — between day, month and year (`5.5.2025`, `5/5/2025`).
  - `shortDateSuffix` — after a date without a year (`5.5.`).
  - `timeSeparator` — between hours and minutes (`9.05`, `9:05`).
  - `datePlaceholder` — hint shown in an empty date input.
  - `invalidDate` — message for a date that cannot be parsed.
  - `firstDayOfWeek` — first column of a calendar.

Dates are always written day first, then month, then year.

-}
type alias Locale =
    { code : String
    , weekdayAbbr : Weekday -> String
    , monthName : Int -> String
    , dateSeparator : String
    , shortDateSuffix : String
    , timeSeparator : String
    , datePlaceholder : String
    , invalidDate : String
    , firstDayOfWeek : Weekday
    }


{-| The locale for a two-letter language code; Finnish for an unknown one.
-}
forCode : String -> Locale
forCode code =
    case code of
        "en" ->
            en

        _ ->
            fi


{-| Finnish.
-}
fi : Locale
fi =
    { code = "fi"
    , weekdayAbbr =
        \weekday ->
            case weekday of
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
    , monthName =
        nth
            [ "Tammikuu"
            , "Helmikuu"
            , "Maaliskuu"
            , "Huhtikuu"
            , "Toukokuu"
            , "Kesäkuu"
            , "Heinäkuu"
            , "Elokuu"
            , "Syyskuu"
            , "Lokakuu"
            , "Marraskuu"
            , "Joulukuu"
            ]
    , dateSeparator = "."
    , shortDateSuffix = "."
    , timeSeparator = "."
    , datePlaceholder = "pp.kk.vvvv"
    , invalidDate = "Virheellinen päivämäärä"
    , firstDayOfWeek = Mon
    }


{-| British English.
-}
en : Locale
en =
    { code = "en"
    , weekdayAbbr =
        \weekday ->
            case weekday of
                Mon ->
                    "Mon"

                Tue ->
                    "Tue"

                Wed ->
                    "Wed"

                Thu ->
                    "Thu"

                Fri ->
                    "Fri"

                Sat ->
                    "Sat"

                Sun ->
                    "Sun"
    , monthName =
        nth
            [ "January"
            , "February"
            , "March"
            , "April"
            , "May"
            , "June"
            , "July"
            , "August"
            , "September"
            , "October"
            , "November"
            , "December"
            ]
    , dateSeparator = "/"
    , shortDateSuffix = ""
    , timeSeparator = ":"
    , datePlaceholder = "dd/mm/yyyy"
    , invalidDate = "Invalid date"
    , firstDayOfWeek = Mon
    }


{-| The name at a 1-based position, or `""` outside the list.
-}
nth : List String -> Int -> String
nth names index =
    names
        |> List.drop (index - 1)
        |> List.head
        |> Maybe.withDefault ""
