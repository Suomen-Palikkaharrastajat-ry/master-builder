module FinnishDateTest exposing (suite)

{-| Test suite for FinnishDate module.
-}

import Date
import Expect
import FinnishDate
import Test exposing (Test, describe, test)
import Time exposing (Month(..), Weekday(..))


suite : Test
suite =
    describe "FinnishDate"
        [ describe "parse and format round-trips"
            [ test "parses 1.2.2026 into 2026-02-01 and formats back" <|
                \_ ->
                    case FinnishDate.parse "1.2.2026" of
                        Ok date ->
                            Expect.all
                                [ \d -> Expect.equal "2026-02-01" (Date.toIsoString d)
                                , \d -> Expect.equal "01.02.2026" (FinnishDate.format d)
                                ]
                                date

                        Err err ->
                            Expect.fail ("Failed to parse: " ++ err)
            , test "parses 31.12.2026 into 2026-12-31 and formats back" <|
                \_ ->
                    case FinnishDate.parse "31.12.2026" of
                        Ok date ->
                            Expect.all
                                [ \d -> Expect.equal "2026-12-31" (Date.toIsoString d)
                                , \d -> Expect.equal "31.12.2026" (FinnishDate.format d)
                                ]
                                date

                        Err err ->
                            Expect.fail ("Failed to parse: " ++ err)
            , test "fails on invalid date 32.1.2026" <|
                \_ ->
                    case FinnishDate.parse "32.1.2026" of
                        Ok _ ->
                            Expect.fail "Should have failed on 32.1.2026"

                        Err _ ->
                            Expect.pass
            , test "fails on non-date strings" <|
                \_ ->
                    case FinnishDate.parse "invalid" of
                        Ok _ ->
                            Expect.fail "Should have failed on invalid string"

                        Err _ ->
                            Expect.pass
            ]
        , describe "monthName"
            [ test "1 is Tammikuu" <|
                \_ ->
                    Expect.equal "Tammikuu" (FinnishDate.monthName 1)
            , test "12 is Joulukuu" <|
                \_ ->
                    Expect.equal "Joulukuu" (FinnishDate.monthName 12)
            ]
        , describe "weekdayAbbr"
            [ test "Mon is ma" <|
                \_ ->
                    Expect.equal "ma" (FinnishDate.weekdayAbbr Mon)
            , test "Sun is su" <|
                \_ ->
                    Expect.equal "su" (FinnishDate.weekdayAbbr Sun)
            ]
        ]
