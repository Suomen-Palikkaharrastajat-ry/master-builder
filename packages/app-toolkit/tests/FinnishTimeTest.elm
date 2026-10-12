module FinnishTimeTest exposing (suite)

{-| Test suite for FinnishTime module.
-}

import Expect
import FinnishTime exposing (..)
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
        , describe "formatTime"
            [ test "formats 14:00 UTC in winter (+2h) as 16.00" <|
                \_ ->
                    -- 2025-01-15 14:00:00 UTC → 16:00 EET
                    Time.millisToPosix 1736949600000
                        |> formatTime
                        |> Expect.equal "16.00"
            , test "formats 14:00 UTC in summer (+3h) as 17.00" <|
                \_ ->
                    -- 2025-06-15 14:00:00 UTC → 17:00 EEST
                    Time.millisToPosix 1750082400000
                        |> formatTime
                        |> Expect.equal "17.00"
            , test "pads single-digit minutes" <|
                \_ ->
                    -- 2025-06-15 14:05:00 UTC → 17:05 EEST
                    Time.millisToPosix 1750082700000
                        |> formatTime
                        |> Expect.equal "17.05"
            ]
        , describe "formatShortDate"
            [ test "formats short date in Helsinki time" <|
                \_ ->
                    -- 2025-05-05 14:00:00 UTC
                    Time.millisToPosix 1746453600000
                        |> formatShortDate
                        |> Expect.equal "5.5."
            ]
        , describe "formatFullDate"
            [ test "formats full date in Helsinki time" <|
                \_ ->
                    -- 2025-05-05 14:00:00 UTC (Monday)
                    Time.millisToPosix 1746453600000
                        |> formatFullDate
                        |> Expect.equal "ma 5.5.2025"
            ]
        , describe "finnishWeekdayAbbr"
            [ test "Mon is ma" <| \_ -> finnishWeekdayAbbr Mon |> Expect.equal "ma"
            , test "Tue is ti" <| \_ -> finnishWeekdayAbbr Tue |> Expect.equal "ti"
            , test "Wed is ke" <| \_ -> finnishWeekdayAbbr Wed |> Expect.equal "ke"
            , test "Thu is to" <| \_ -> finnishWeekdayAbbr Thu |> Expect.equal "to"
            , test "Fri is pe" <| \_ -> finnishWeekdayAbbr Fri |> Expect.equal "pe"
            , test "Sat is la" <| \_ -> finnishWeekdayAbbr Sat |> Expect.equal "la"
            , test "Sun is su" <| \_ -> finnishWeekdayAbbr Sun |> Expect.equal "su"
            ]
        , describe "finnishMonthName"
            [ test "January is Tammikuu" <| \_ -> finnishMonthName 1 |> Expect.equal "Tammikuu"
            , test "May is Toukokuu" <| \_ -> finnishMonthName 5 |> Expect.equal "Toukokuu"
            , test "December is Joulukuu" <| \_ -> finnishMonthName 12 |> Expect.equal "Joulukuu"
            ]
        , describe "daysInMonth"
            [ test "February in non-leap year" <| \_ -> daysInMonth 2025 2 |> Expect.equal 28
            , test "February in leap year" <| \_ -> daysInMonth 2024 2 |> Expect.equal 29
            , test "April has 30 days" <| \_ -> daysInMonth 2025 4 |> Expect.equal 30
            , test "May has 31 days" <| \_ -> daysInMonth 2025 5 |> Expect.equal 31
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
        , describe "Finnish date input conversions"
            [ test "isoDateToFinnishDateInput: 2026-02-01 → 01.02.2026" <|
                \_ ->
                    isoDateToFinnishDateInput "2026-02-01"
                        |> Expect.equal "01.02.2026"
            , test "finnishDateInputToIsoDate: 1.2.2026 → 2026-02-01" <|
                \_ ->
                    finnishDateInputToIsoDate "1.2.2026"
                        |> Expect.equal (Just "2026-02-01")
            , test "finnishDateInputToIsoDate: 01.02.2026 → 2026-02-01" <|
                \_ ->
                    finnishDateInputToIsoDate "01.02.2026"
                        |> Expect.equal (Just "2026-02-01")
            , test "finnishDateInputToIsoDate: invalid date → Nothing" <|
                \_ ->
                    finnishDateInputToIsoDate "31.02.2026"
                        |> Expect.equal Nothing
            ]
        ]
