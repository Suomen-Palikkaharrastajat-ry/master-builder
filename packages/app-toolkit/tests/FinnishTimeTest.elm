module FinnishTimeTest exposing (suite)

{-| Test suite for FinnishTime module.
-}

import Date
import Expect
import FinnishTime
    exposing
        ( DateParts
        , dateInputToIsoDate
        , daysInMonth
        , firstDayOfWeek
        , formDateTimeToUtc
        , formatDate
        , formatFullDate
        , formatShortDate
        , formatTime
        , helsinkiOffset
        , helsinkiZone
        , isDst
        , isoDateToDateInput
        , monthGrid
        , monthName
        , monthToInt
        , nextMonth
        , parseDate
        , parseUtcString
        , prevMonth
        , toHelsinkiParts
        , utcStringToHelsinkiDateInput
        , utcStringToHelsinkiTimeInput
        , weekdayAbbr
        )
import Locale
import Test exposing (Test, describe, test)
import Time exposing (Month(..), Posix, Weekday(..))


suite : Test
suite =
    describe "FinnishTime"
        [ describe "parseUtcString"
            [ test "parses valid UTC ISO string with T" <|
                \_ ->
                    parseUtcString "2025-05-05T14:00:00.000Z"
                        |> Maybe.map Time.posixToMillis
                        |> Expect.equal (Just 1746453600000)
            , test "parses PocketBase format with space separator" <|
                \_ ->
                    parseUtcString "2025-05-05 14:00:00.000Z"
                        |> Maybe.map Time.posixToMillis
                        |> Expect.equal (Just 1746453600000)
            , test "returns Nothing on invalid string" <|
                \_ ->
                    parseUtcString "invalid-date"
                        |> Expect.equal Nothing
            ]
        , describe "helsinkiOffset and isDst"
            [ test "winter time (EET) is UTC+2 = 120 min" <|
                \_ ->
                    -- 2025-01-15 12:00:00 UTC
                    Time.millisToPosix 1736942400000
                        |> helsinkiOffset
                        |> Expect.equal 120
            , test "summer time (EEST) is UTC+3 = 180 min" <|
                \_ ->
                    -- 2025-06-15 12:00:00 UTC
                    Time.millisToPosix 1750075200000
                        |> helsinkiOffset
                        |> Expect.equal 180
            , test "winter is not DST" <|
                \_ ->
                    Time.millisToPosix 1736942400000
                        |> isDst
                        |> Expect.equal False
            , test "summer is DST" <|
                \_ ->
                    Time.millisToPosix 1750075200000
                        |> isDst
                        |> Expect.equal True
            ]
        , describe "helsinkiZone and toHelsinkiParts"
            [ test "helsinkiZone produces correct local hour" <|
                \_ ->
                    let
                        posix =
                            Time.millisToPosix 1750075200000

                        -- 12:00 UTC -> 15:00 Helsinki (UTC+3)
                        zone =
                            helsinkiZone posix
                    in
                    Time.toHour zone posix |> Expect.equal 15
            , test "toHelsinkiParts decomposes Posix into date parts" <|
                \_ ->
                    let
                        -- 2025-05-05 14:30:00 UTC -> 17:30 Helsinki (Monday)
                        posix =
                            Time.millisToPosix 1746455400000
                    in
                    toHelsinkiParts posix
                        |> Expect.equal
                            { year = 2025
                            , month = 5
                            , day = 5
                            , hour = 17
                            , minute = 30
                            , weekday = Mon
                            }
            ]
        , describe "formatTime"
            [ test "formats 14:00 UTC in winter (+2h) as 16.00" <|
                \_ ->
                    -- 2025-01-15 14:00:00 UTC → 16:00 EET
                    Time.millisToPosix 1736949600000
                        |> formatTime Locale.fi
                        |> Expect.equal "16.00"
            , test "formats 14:00 UTC in summer (+3h) as 17.00" <|
                \_ ->
                    -- 2025-06-15 14:00:00 UTC → 17:00 EEST
                    Time.millisToPosix 1750082400000
                        |> formatTime Locale.fi
                        |> Expect.equal "17.00"
            , test "pads single-digit minutes" <|
                \_ ->
                    -- 2025-06-15 14:05:00 UTC → 17:05 EEST
                    Time.millisToPosix 1750082700000
                        |> formatTime Locale.fi
                        |> Expect.equal "17.05"
            ]
        , describe "formatShortDate"
            [ test "formats short date in Helsinki time" <|
                \_ ->
                    -- 2025-05-05 14:00:00 UTC
                    Time.millisToPosix 1746453600000
                        |> formatShortDate Locale.fi
                        |> Expect.equal "5.5."
            ]
        , describe "formatFullDate"
            [ test "formats full date in Helsinki time" <|
                \_ ->
                    -- 2025-05-05 14:00:00 UTC (Monday)
                    Time.millisToPosix 1746453600000
                        |> formatFullDate Locale.fi
                        |> Expect.equal "ma 5.5.2025"
            ]
        , describe "weekdayAbbr Locale.fi and weekdayAbbr"
            [ test "Mon is ma" <| \_ -> weekdayAbbr Locale.fi Mon |> Expect.equal "ma"
            , test "Tue is ti" <| \_ -> weekdayAbbr Locale.fi Tue |> Expect.equal "ti"
            , test "Wed is ke" <| \_ -> weekdayAbbr Locale.fi Wed |> Expect.equal "ke"
            , test "Thu is to" <| \_ -> weekdayAbbr Locale.fi Thu |> Expect.equal "to"
            , test "Fri is pe" <| \_ -> weekdayAbbr Locale.fi Fri |> Expect.equal "pe"
            , test "Sat is la" <| \_ -> weekdayAbbr Locale.fi Sat |> Expect.equal "la"
            , test "Sun is su" <| \_ -> weekdayAbbr Locale.fi Sun |> Expect.equal "su"
            , test "English weekday" <| \_ -> weekdayAbbr Locale.en Mon |> Expect.equal "Mon"
            ]
        , describe "monthName Locale.fi and monthName"
            [ test "January is Tammikuu" <| \_ -> monthName Locale.fi 1 |> Expect.equal "Tammikuu"
            , test "May is Toukokuu" <| \_ -> monthName Locale.fi 5 |> Expect.equal "Toukokuu"
            , test "December is Joulukuu" <| \_ -> monthName Locale.fi 12 |> Expect.equal "Joulukuu"
            , test "English month" <| \_ -> monthName Locale.en 5 |> Expect.equal "May"
            ]
        , describe "monthToInt"
            [ test "converts Jan to 1" <| \_ -> monthToInt Jan |> Expect.equal 1
            , test "converts Jun to 6" <| \_ -> monthToInt Jun |> Expect.equal 6
            , test "converts Dec to 12" <| \_ -> monthToInt Dec |> Expect.equal 12
            ]
        , describe "daysInMonth and firstDayOfWeek"
            [ test "February in non-leap year" <| \_ -> daysInMonth 2025 2 |> Expect.equal 28
            , test "February in leap year" <| \_ -> daysInMonth 2024 2 |> Expect.equal 29
            , test "April has 30 days" <| \_ -> daysInMonth 2025 4 |> Expect.equal 30
            , test "May has 31 days" <| \_ -> daysInMonth 2025 5 |> Expect.equal 31
            , test "firstDayOfWeek 2025-05 starts on Thursday (index 3)" <|
                \_ ->
                    firstDayOfWeek 2025 5 |> Expect.equal 3
            ]
        , describe "calendar grid helpers"
            [ test "prevMonth handles January" <|
                \_ ->
                    prevMonth 2025 1 |> Expect.equal ( 2024, 12 )
            , test "nextMonth handles December" <|
                \_ ->
                    nextMonth 2025 12 |> Expect.equal ( 2026, 1 )
            , test "monthGrid generates 42 cells" <|
                \_ ->
                    monthGrid 2025 5
                        |> List.concat
                        |> List.length
                        |> Expect.equal 42
            ]
        , describe "formDateTimeToUtc"
            [ test "converts summer time inputs correctly (UTC+3)" <|
                \_ ->
                    -- 2025-06-15 17:00 in Helsinki is 14:00 UTC
                    formDateTimeToUtc "2025-06-15" "17:00" False
                        |> Expect.equal (Just "2025-06-15T14:00:00.000Z")
            , test "converts winter time inputs correctly (UTC+2)" <|
                \_ ->
                    -- 2025-01-15 16:00 in Helsinki is 14:00 UTC
                    formDateTimeToUtc "2025-01-15" "16:00" False
                        |> Expect.equal (Just "2025-01-15T14:00:00.000Z")
            , test "handles allDay event at midnight Helsinki time" <|
                \_ ->
                    -- 2025-06-15 00:00 in Helsinki is 2025-06-14 21:00 UTC
                    formDateTimeToUtc "2025-06-15" "" True
                        |> Expect.equal (Just "2025-06-14T21:00:00.000Z")
            ]
        , describe "date input conversions and parsing"
            [ test "isoDateToDateInput: 2026-02-01 → 01.02.2026" <|
                \_ ->
                    isoDateToDateInput Locale.fi "2026-02-01"
                        |> Expect.equal "01.02.2026"
            , test "dateInputToIsoDate: 1.2.2026 → 2026-02-01" <|
                \_ ->
                    dateInputToIsoDate Locale.fi "1.2.2026"
                        |> Expect.equal (Just "2026-02-01")
            , test "dateInputToIsoDate: 01.02.2026 → 2026-02-01" <|
                \_ ->
                    dateInputToIsoDate Locale.fi "01.02.2026"
                        |> Expect.equal (Just "2026-02-01")
            , test "dateInputToIsoDate: invalid date → Nothing" <|
                \_ ->
                    dateInputToIsoDate Locale.fi "31.02.2026"
                        |> Expect.equal Nothing
            , test "parseDate and formatDate round-trip" <|
                \_ ->
                    case parseDate Locale.fi "05.05.2025" of
                        Ok date ->
                            formatDate Locale.fi date |> Expect.equal "05.05.2025"

                        Err err ->
                            Expect.fail err
            , test "parseDate returns Err on invalid date" <|
                \_ ->
                    case parseDate Locale.fi "invalid" of
                        Ok _ ->
                            Expect.fail "Expected error for invalid date"

                        Err _ ->
                            Expect.pass
            ]
        , describe "English locale"
            [ test "date input uses slashes" <|
                \_ ->
                    isoDateToDateInput Locale.en "2026-02-01"
                        |> Expect.equal "01/02/2026"
            , test "date input parses back" <|
                \_ ->
                    dateInputToIsoDate Locale.en "1/2/2026"
                        |> Expect.equal (Just "2026-02-01")
            , test "invalid date message is English" <|
                \_ ->
                    parseDate Locale.en "nope"
                        |> Expect.equal (Err "Invalid date")
            ]
        , describe "utcStringToHelsinki inputs"
            [ test "converts UTC string to Helsinki date input YYYY-MM-DD" <|
                \_ ->
                    utcStringToHelsinkiDateInput "2025-06-15T14:00:00.000Z"
                        |> Expect.equal "2025-06-15"
            , test "converts UTC string to Helsinki time input HH:MM" <|
                \_ ->
                    utcStringToHelsinkiTimeInput "2025-06-15T14:00:00.000Z"
                        |> Expect.equal "17:00"
            , test "returns empty string on invalid UTC string" <|
                \_ ->
                    Expect.all
                        [ \_ -> utcStringToHelsinkiDateInput "bad" |> Expect.equal ""
                        , \_ -> utcStringToHelsinkiTimeInput "bad" |> Expect.equal ""
                        ]
                        ()
            ]
        ]
