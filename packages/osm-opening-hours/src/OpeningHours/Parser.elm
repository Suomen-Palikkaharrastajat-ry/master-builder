module OpeningHours.Parser exposing (parse)

import Parser exposing (Parser, (|.), (|=), symbol, keyword, succeed, int, spaces, oneOf, end, sequence, lazy, backtrackable, getChompedString, chompWhile, andThen, problem)
import OpeningHours exposing (..)

parse : String -> Result (List Parser.DeadEnd) OpeningHours
parse input =
    Parser.run (openingHoursParser |. end) (String.trim input)

openingHoursParser : Parser OpeningHours
openingHoursParser =
    oneOf
        [ succeed Open247 |. keyword "24/7"
        , succeed Rules |= rulesParser
        ]

rulesParser : Parser (List Rule)
rulesParser =
    sequence
        { start = ""
        , separator = ";"
        , end = ""
        , spaces = spaces
        , item = lazy (\_ -> ruleParser)
        , trailing = Parser.Optional
        }

ruleParser : Parser Rule
ruleParser =
    succeed Rule
        |= optional (lazy (\_ -> monthsWithColonParser))
        |= optional (lazy (\_ -> daysParser))
        |. spaces
        |= lazy (\_ -> ruleStatusParser)

monthsWithColonParser : Parser (List MonthSelector)
monthsWithColonParser =
    succeed identity
        |= lazy (\_ -> monthSelectorsParser)
        |. spaces
        |. symbol ":"
        |. spaces

monthSelectorsParser : Parser (List MonthSelector)
monthSelectorsParser =
    sequence
        { start = ""
        , separator = ","
        , end = ""
        , spaces = spaces
        , item = lazy (\_ -> monthSelectorParser)
        , trailing = Parser.Forbidden
        }
        |> andThen (\list ->
            case list of
                [] -> problem "empty months"
                _ -> succeed list
        )

monthSelectorParser : Parser MonthSelector
monthSelectorParser =
    oneOf
        [ backtrackable <|
            succeed MonthRange
                |= monthParser
                |. symbol "-"
                |= monthParser
        , succeed SingleMonth
            |= monthParser
        ]

monthParser : Parser Month
monthParser =
    oneOf
        [ succeed Jan |. keyword "Jan"
        , succeed Feb |. keyword "Feb"
        , succeed Mar |. keyword "Mar"
        , succeed Apr |. keyword "Apr"
        , succeed May |. keyword "May"
        , succeed Jun |. keyword "Jun"
        , succeed Jul |. keyword "Jul"
        , succeed Aug |. keyword "Aug"
        , succeed Sep |. keyword "Sep"
        , succeed Oct |. keyword "Oct"
        , succeed Nov |. keyword "Nov"
        , succeed Dec |. keyword "Dec"
        ]

daysParser : Parser (List DaySelector)
daysParser =
    sequence
        { start = ""
        , separator = ","
        , end = ""
        , spaces = spaces
        , item = lazy (\_ -> daySelectorParser)
        , trailing = Parser.Forbidden
        }
        |> andThen (\list ->
            case list of
                [] -> problem "empty days"
                _ -> succeed list
        )

daySelectorParser : Parser DaySelector
daySelectorParser =
    oneOf
        [ succeed PublicHoliday |. keyword "PH"
        , backtrackable <|
            succeed DayRange
                |= dayParser
                |. symbol "-"
                |= dayParser
        , succeed SingleDay
            |= dayParser
        ]

-- Wait, "Mo,We,Fr" parsed as sequence gives `[SingleDay Mo, SingleDay We, SingleDay Fr]`.
-- But my test says: `[DayList [Mo, We, Fr]]` for "Mo,We,Fr". 
-- Actually, the OSM spec treats comma separated as a list of selectors.
-- Let's change the domain model or adapt the parser to match the test.
-- The test expects: DayList [Mo, We, Fr]. 
-- But wait! It's simpler if "Mo,We,Fr" is parsed as [SingleDay Mo, SingleDay We, SingleDay Fr] by the sequence!
-- Let's stick to sequence for daysParser, and I'll adjust the test instead, because comma separation just means a list of selectors in OSM.
-- I'll use the sequence as is. Let's write the day parser.

dayParser : Parser Day
dayParser =
    oneOf
        [ succeed Mo |. keyword "Mo"
        , succeed Tu |. keyword "Tu"
        , succeed We |. keyword "We"
        , succeed Th |. keyword "Th"
        , succeed Fr |. keyword "Fr"
        , succeed Sa |. keyword "Sa"
        , succeed Su |. keyword "Su"
        ]

ruleStatusParser : Parser RuleStatus
ruleStatusParser =
    oneOf
        [ succeed Off |. keyword "off"
        , succeed Open |= timeSpansParser
        ]

timeSpansParser : Parser (List TimeSpan)
timeSpansParser =
    sequence
        { start = ""
        , separator = ","
        , end = ""
        , spaces = spaces
        , item = lazy (\_ -> timeSpanParser)
        , trailing = Parser.Forbidden
        }
        |> andThen (\list ->
            case list of
                [] -> problem "empty times"
                _ -> succeed list
        )

timeSpanParser : Parser TimeSpan
timeSpanParser =
    oneOf
        [ backtrackable <|
            succeed TimeRange
                |= timeParser
                |. symbol "-"
                |= timeParser
        , succeed OpenEnded
            |= timeParser
            |. symbol "+"
        ]

timeParser : Parser Time
timeParser =
    succeed Time
        |= intParser
        |. symbol ":"
        |= intParser

intParser : Parser Int
intParser =
    getChompedString (chompWhile Char.isDigit)
        |> andThen (\str ->
            case String.toInt str of
                Just n -> succeed n
                Nothing -> problem "invalid int"
        )

optional : Parser a -> Parser (Maybe a)
optional p =
    oneOf
        [ succeed Just |= backtrackable p
        , succeed Nothing
        ]
