module FinnishTime exposing (DateParts, daysInMonth, dateInputToIsoDate, firstDayOfWeek, formDateTimeToUtc, formatDate, formatFullDate, formatShortDate, formatTime, helsinkiOffset, helsinkiZone, isDst, isoDateToDateInput, monthGrid, monthName, monthToInt, nextMonth, parseDate, parseUtcString, prevMonth, toHelsinkiParts, utcStringToHelsinkiDateInput, utcStringToHelsinkiTimeInput, weekdayAbbr)

{-| Date and time utilities for Helsinki time: UTC/Helsinki conversion, calendar
grids, and formatting and parsing in a given `Locale`.

@docs DateParts, daysInMonth, dateInputToIsoDate, firstDayOfWeek, formDateTimeToUtc, formatDate, formatFullDate, formatShortDate, formatTime, helsinkiOffset, helsinkiZone, isDst, isoDateToDateInput, monthGrid, monthName, monthToInt, nextMonth, parseDate, parseUtcString, prevMonth, toHelsinkiParts, utcStringToHelsinkiDateInput, utcStringToHelsinkiTimeInput, weekdayAbbr

-}

import Date exposing (Date)
import Iso8601
import Locale exposing (Locale)
import Time exposing (Month(..), Posix, Weekday(..), Zone)


{-| Components of a date and time localized to Helsinki time.
-}
type alias DateParts =
    { year : Int
    , month : Int
    , day : Int
    , hour : Int
    , minute : Int
    , weekday : Weekday
    }


{-| Helsinki timezone offset in minutes from UTC (120 min for EET, 180 min for EEST).
-}
helsinkiOffset : Posix -> Int
helsinkiOffset posix =
    if isDst posix then
        180

    else
        120


{-| Checks if a UTC time falls within Helsinki Daylight Saving Time (EEST).
DST begins the last Sunday of March at 01:00 UTC and ends the last Sunday of October at 01:00 UTC.
-}
isDst : Posix -> Bool
isDst posix =
    let
        year =
            Time.toYear Time.utc posix

        dstStart =
            lastSundayOfAt year 3 1

        dstEnd =
            lastSundayOfAt year 10 1
    in
    Time.posixToMillis posix
        >= Time.posixToMillis dstStart
        && Time.posixToMillis posix
        < Time.posixToMillis dstEnd


lastSundayOfAt : Int -> Int -> Int -> Posix
lastSundayOfAt year month hourUtc =
    let
        days =
            daysInMonth year month

        lastDayMs =
            dateToMillis year month days 0 0

        lastDayWeekday =
            Time.toWeekday Time.utc (Time.millisToPosix lastDayMs)

        sundayBack =
            case lastDayWeekday of
                Sun ->
                    0

                Mon ->
                    1

                Tue ->
                    2

                Wed ->
                    3

                Thu ->
                    4

                Fri ->
                    5

                Sat ->
                    6
    in
    Time.millisToPosix (lastDayMs - sundayBack * 86400000 + hourUtc * 3600000)


weekdayToMondayOffset : Weekday -> Int
weekdayToMondayOffset w =
    case w of
        Mon ->
            0

        Tue ->
            1

        Wed ->
            2

        Thu ->
            3

        Fri ->
            4

        Sat ->
            5

        Sun ->
            6


dateToMillis : Int -> Int -> Int -> Int -> Int -> Int
dateToMillis year month day hour minute =
    let
        yearDays =
            List.sum
                (List.map
                    (\y ->
                        if isLeapYear y then
                            366

                        else
                            365
                    )
                    (List.range 1970 (year - 1))
                )

        monthDays =
            List.sum
                (List.map
                    (\m -> daysInMonth year m)
                    (List.range 1 (month - 1))
                )

        totalDays =
            yearDays + monthDays + day - 1
    in
    totalDays * 86400000 + hour * 3600000 + minute * 60000


isLeapYear : Int -> Bool
isLeapYear y =
    (modBy 4 y == 0 && modBy 100 y /= 0) || modBy 400 y == 0


{-| Returns the `Time.Zone` for Helsinki at the given instant.
-}
helsinkiZone : Posix -> Zone
helsinkiZone posix =
    Time.customZone (helsinkiOffset posix) []


{-| Decomposes a UTC `Posix` instant into Helsinki-local parts (year, month, day, hour, minute, weekday).
-}
toHelsinkiParts : Posix -> DateParts
toHelsinkiParts posix =
    let
        zone =
            helsinkiZone posix
    in
    { year = Time.toYear zone posix
    , month = monthToInt (Time.toMonth zone posix)
    , day = Time.toDay zone posix
    , hour = Time.toHour zone posix
    , minute = Time.toMinute zone posix
    , weekday = Time.toWeekday zone posix
    }


{-| Converts a `Time.Month` to a 1-based integer (1–12).
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


{-| Parses a UTC ISO 8601 string to a Posix time. Normalizes space-separated PocketBase timestamps.
-}
parseUtcString : String -> Maybe Posix
parseUtcString s =
    case Iso8601.toTime (String.replace " " "T" s) of
        Ok posix ->
            Just posix

        Err _ ->
            Nothing


{-| Abbreviated weekday name in the locale (`"ma"`, `"Mon"`).
-}
weekdayAbbr : Locale -> Weekday -> String
weekdayAbbr locale =
    locale.weekdayAbbr


{-| Capitalized month name in the locale for month index 1–12 (`"Tammikuu"`).
-}
monthName : Locale -> Int -> String
monthName locale =
    locale.monthName


{-| Formats a Posix instant as a date without year (`"5.5."`) in Helsinki time.
-}
formatShortDate : Locale -> Posix -> String
formatShortDate locale posix =
    let
        parts =
            toHelsinkiParts posix
    in
    String.fromInt parts.day ++ locale.dateSeparator ++ String.fromInt parts.month ++ locale.shortDateSuffix


{-| Formats a Posix instant as a time of day (`"9.05"`) in Helsinki time.
-}
formatTime : Locale -> Posix -> String
formatTime locale posix =
    let
        parts =
            toHelsinkiParts posix
    in
    String.fromInt parts.hour ++ locale.timeSeparator ++ pad2 parts.minute


{-| Formats a Posix instant as weekday and date (`"ma 5.5.2025"`) in Helsinki time.
-}
formatFullDate : Locale -> Posix -> String
formatFullDate locale posix =
    let
        parts =
            toHelsinkiParts posix
    in
    locale.weekdayAbbr parts.weekday
        ++ " "
        ++ String.fromInt parts.day
        ++ locale.dateSeparator
        ++ String.fromInt parts.month
        ++ locale.dateSeparator
        ++ String.fromInt parts.year


{-| Convert Helsinki-local date and time input strings to a UTC ISO 8601 string.
-}
formDateTimeToUtc : String -> String -> Bool -> Maybe String
formDateTimeToUtc dateStr timeStr allDay =
    case String.split "-" dateStr of
        [ yearS, monthS, dayS ] ->
            case ( String.toInt yearS, String.toInt monthS, String.toInt dayS ) of
                ( Just year, Just month, Just day ) ->
                    let
                        ( hour, minute ) =
                            if allDay then
                                ( 0, 0 )

                            else
                                case String.split ":" timeStr of
                                    [ hS, mS ] ->
                                        ( Maybe.withDefault 0 (String.toInt hS)
                                        , Maybe.withDefault 0 (String.toInt mS)
                                        )

                                    _ ->
                                        ( 0, 0 )

                        localMs =
                            dateToMillis year month day hour minute

                        approxUtcPosix =
                            Time.millisToPosix (localMs - 120 * 60000)

                        offsetMins =
                            helsinkiOffset approxUtcPosix

                        utcPosix =
                            Time.millisToPosix (localMs - offsetMins * 60000)
                    in
                    Just (Iso8601.fromTime utcPosix)

                _ ->
                    Nothing

        _ ->
            Nothing


{-| Convert a UTC ISO string to `"YYYY-MM-DD"` in Helsinki time.
-}
utcStringToHelsinkiDateInput : String -> String
utcStringToHelsinkiDateInput utcStr =
    case parseUtcString utcStr of
        Nothing ->
            ""

        Just posix ->
            let
                parts =
                    toHelsinkiParts posix
            in
            String.fromInt parts.year
                ++ "-"
                ++ pad2 parts.month
                ++ "-"
                ++ pad2 parts.day


{-| Convert a UTC ISO string to `"HH:MM"` in Helsinki time.
-}
utcStringToHelsinkiTimeInput : String -> String
utcStringToHelsinkiTimeInput utcStr =
    case parseUtcString utcStr of
        Nothing ->
            ""

        Just posix ->
            let
                parts =
                    toHelsinkiParts posix
            in
            pad2 parts.hour ++ ":" ++ pad2 parts.minute


{-| Convert an ISO date string (`"YYYY-MM-DD"`) to the locale's date input
format (`"DD.MM.YYYY"`).
-}
isoDateToDateInput : Locale -> String -> String
isoDateToDateInput locale isoDate =
    case Date.fromIsoString isoDate of
        Ok date ->
            pad2 (Date.day date)
                ++ locale.dateSeparator
                ++ pad2 (Date.monthNumber date)
                ++ locale.dateSeparator
                ++ String.fromInt (Date.year date)

        Err _ ->
            ""


{-| Convert the locale's date input format (`"DD.MM.YYYY"`) to an ISO date
(`"YYYY-MM-DD"`).
-}
dateInputToIsoDate : Locale -> String -> Maybe String
dateInputToIsoDate locale input =
    case String.split locale.dateSeparator (String.trim input) of
        [ dayStr, monthStr, yearStr ] ->
            case ( String.toInt dayStr, String.toInt monthStr, String.toInt yearStr ) of
                ( Just day, Just month, Just year ) ->
                    (String.fromInt year ++ "-" ++ pad2 month ++ "-" ++ pad2 day)
                        |> Date.fromIsoString
                        |> Result.toMaybe
                        |> Maybe.map Date.toIsoString

                _ ->
                    Nothing

        _ ->
            Nothing


{-| Parse a date in the locale's input format into a `Date`.
-}
parseDate : Locale -> String -> Result String Date
parseDate locale input =
    case dateInputToIsoDate locale input of
        Just isoDate ->
            Date.fromIsoString isoDate

        Nothing ->
            Err locale.invalidDate


{-| Format a `Date` in the locale's input format (`"DD.MM.YYYY"`).
-}
formatDate : Locale -> Date -> String
formatDate locale date =
    isoDateToDateInput locale (Date.toIsoString date)


{-| Returns the number of days in a given month (1-indexed). Handles leap years.
-}
daysInMonth : Int -> Int -> Int
daysInMonth year month =
    case month of
        2 ->
            if isLeapYear year then
                29

            else
                28

        m ->
            if List.member m [ 4, 6, 9, 11 ] then
                30

            else
                31


{-| Day of week of the 1st of the month (0=Monday, 6=Sunday).
-}
firstDayOfWeek : Int -> Int -> Int
firstDayOfWeek year month =
    let
        firstMs =
            dateToMillis year month 1 0 0

        weekday =
            Time.toWeekday Time.utc (Time.millisToPosix firstMs)
    in
    weekdayToMondayOffset weekday


{-| Generates a 6×7 calendar month grid of days (`Maybe Int`).
-}
monthGrid : Int -> Int -> List (List (Maybe Int))
monthGrid year month =
    let
        offset =
            firstDayOfWeek year month

        days =
            daysInMonth year month

        total =
            6 * 7

        cells =
            List.map
                (\i ->
                    if i < offset || i >= offset + days then
                        Nothing

                    else
                        Just (i - offset + 1)
                )
                (List.range 0 (total - 1))
    in
    chunk 7 cells


chunk : Int -> List a -> List (List a)
chunk n list =
    if List.isEmpty list then
        []

    else
        List.take n list :: chunk n (List.drop n list)


{-| Previous month as `(year, month)`.
-}
prevMonth : Int -> Int -> ( Int, Int )
prevMonth year month =
    if month == 1 then
        ( year - 1, 12 )

    else
        ( year, month - 1 )


{-| Next month as `(year, month)`.
-}
nextMonth : Int -> Int -> ( Int, Int )
nextMonth year month =
    if month == 12 then
        ( year + 1, 1 )

    else
        ( year, month + 1 )


pad2 : Int -> String
pad2 n =
    if n < 10 then
        "0" ++ String.fromInt n

    else
        String.fromInt n
