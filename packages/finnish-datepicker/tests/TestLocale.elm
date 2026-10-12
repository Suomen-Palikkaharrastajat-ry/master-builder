module TestLocale exposing (fi)

{-| A Finnish locale for the tests; apps pass `Locale.fi` from the app toolkit.
-}

import Time exposing (Weekday(..))


{-| Finnish date conventions, as far as the date picker needs them.
-}
fi :
    { dateSeparator : String
    , datePlaceholder : String
    , invalidDate : String
    , weekdayAbbr : Weekday -> String
    , monthName : Int -> String
    , firstDayOfWeek : Weekday
    }
fi =
    { dateSeparator = "."
    , datePlaceholder = "pp.kk.vvvv"
    , invalidDate = "Virheellinen päivämäärä"
    , weekdayAbbr =
        \weekday ->
            case weekday of
                Mon ->
                    "ma"

                Sun ->
                    "su"

                _ ->
                    "?"
    , monthName =
        \month ->
            case month of
                1 ->
                    "Tammikuu"

                12 ->
                    "Joulukuu"

                _ ->
                    "?"
    , firstDayOfWeek = Mon
    }
