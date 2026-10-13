module LocaleTest exposing (suite)

{-| `Locale` against the shared table of month and weekday names
(packages/site-config/locales.json), which the Haskell feed generators use too.
-}

import Expect
import Locale
import LocaleNames
import Test exposing (Test, describe, test)
import Time exposing (Weekday(..))


suite : Test
suite =
    describe "Locale"
        (List.map
            (\( code, names ) ->
                let
                    locale =
                        Locale.forCode code
                in
                describe code
                    [ test "is the locale of its code" <|
                        \_ -> locale.code |> Expect.equal code
                    , test "month names match the shared table" <|
                        \_ ->
                            List.map locale.monthName (List.range 1 12)
                                |> Expect.equal names.months
                    , test "weekday abbreviations match the shared table" <|
                        \_ ->
                            List.map locale.weekdayAbbr [ Mon, Tue, Wed, Thu, Fri, Sat, Sun ]
                                |> Expect.equal names.weekdays
                    ]
            )
            LocaleNames.names
        )
