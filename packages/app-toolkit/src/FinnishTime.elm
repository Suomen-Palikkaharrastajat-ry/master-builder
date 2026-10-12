module FinnishTime exposing (DateParts, daysInMonth, finnishDateInputToIsoDate, finnishMonthName, finnishWeekdayAbbr, firstDayOfWeek, formDateTimeToUtc, formatFinnishDate, formatFullDate, formatShortDate, formatTime, helsinkiOffset, helsinkiZone, isDst, isoDateToFinnishDateInput, monthGrid, monthName, monthToInt, nextMonth, parseFinnishDate, parseUtcString, prevMonth, toHelsinkiParts, utcStringToHelsinkiDateInput, utcStringToHelsinkiTimeInput, weekdayAbbr)

{-| Finnish date and time utilities: UTC/Helsinki timezone conversion, formatting,
calendar grids, and localized date parsing.

@docs DateParts, daysInMonth, finnishDateInputToIsoDate, finnishMonthName, finnishWeekdayAbbr, firstDayOfWeek, formDateTimeToUtc, formatFinnishDate, formatFullDate, formatShortDate, formatTime, helsinkiOffset, helsinkiZone, isDst, isoDateToFinnishDateInput, monthGrid, monthName, monthToInt, nextMonth, parseFinnishDate, parseUtcString, prevMonth, toHelsinkiParts, utcStringToHelsinkiDateInput, utcStringToHelsinkiTimeInput, weekdayAbbr

-}

import Date exposing (Date)
import Iso8601
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


{-| Two-letter abbreviation for a Finnish weekday (`"ma"`, `"ti"`, etc.).
-}
finnishWeekdayAbbr : Weekday -> String
finnishWeekdayAbbr w =
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


{-| Alias for `finnishWeekdayAbbr`.
-}
weekdayAbbr : Weekday -> String
weekdayAbbr =
    finnishWeekdayAbbr


{-| Capitalized Finnish month name for month index 1–12 (`"Tammikuu"`, etc.).
-}
finnishMonthName : Int -> String
finnishMonthName m =
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


{-| Alias for `finnishMonthName`.
-}
monthName : Int -> String
monthName =
    finnishMonthName


{-| Formats a Posix instant as `"D.M."` in Helsinki time.
-}
formatShortDate : Posix -> String
formatShortDate posix =
    let
        parts =
            toHelsinkiParts posix
    in
    String.fromInt parts.day ++ "." ++ String.fromInt parts.month ++ "."


{-| Formats a Posix instant as `"H.MM"` (Finnish time format) in Helsinki time.
-}
formatTime : Posix -> String
formatTime posix =
    let
        parts =
            toHelsinkiParts posix

        paddedMin =
            if parts.minute < 10 then
                "0" ++ String.fromInt parts.minute

            else
                String.fromInt parts.minute
    in
    String.fromInt parts.hour ++ "." ++ paddedMin


{-| Formats a Posix instant as `"ma 5.5.2025"` in Helsinki time.
-}
formatFullDate : Posix -> String
formatFullDate posix =
    let
        parts =
            toHelsinkiParts posix
    in
    finnishWeekdayAbbr parts.weekday
        ++ " "
        ++ String.fromInt parts.day
        ++ "."
        ++ String.fromInt parts.month
        ++ "."
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


{-| Convert an ISO date string (`"YYYY-MM-DD"`) to Finnish display format (`"DD.MM.YYYY"`).
-}
isoDateToFinnishDateInput : String -> String
isoDateToFinnishDateInput isoDate =
    case Date.fromIsoString isoDate of
        Ok date ->
            pad2 (Date.day date)
                ++ "."
                ++ pad2 (Date.monthNumber date)
                ++ "."
                ++ String.fromInt (Date.year date)

        Err _ ->
            ""


{-| Convert Finnish display format (`"DD.MM.YYYY"`) to ISO date (`"YYYY-MM-DD"`).
-}
finnishDateInputToIsoDate : String -> Maybe String
finnishDateInputToIsoDate finnishDate =
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
                    case Date.fromIsoString isoCandidate of
                        Ok validDate ->
                            Just (Date.toIsoString validDate)

                        Err _ ->
                            Nothing

                _ ->
                    Nothing

        _ ->
            Nothing


{-| Parse Finnish format date (`"DD.MM.YYYY"`) into a `Date`.
-}
parseFinnishDate : String -> Result String Date
parseFinnishDate finnishDate =
    case finnishDateInputToIsoDate finnishDate of
        Just isoDate ->
            Date.fromIsoString isoDate

        Nothing ->
            Err "Virheellinen päivämäärä"


{-| Format a `Date` in Finnish numerical format (`"DD.MM.YYYY"`).
-}
formatFinnishDate : Date -> String
formatFinnishDate date =
    isoDateToFinnishDateInput (Date.toIsoString date)


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
