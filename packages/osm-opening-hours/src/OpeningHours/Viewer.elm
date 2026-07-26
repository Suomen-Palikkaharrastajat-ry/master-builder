module OpeningHours.Viewer exposing (view, formatToString)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import OpeningHours exposing (..)
import OpeningHours.I18n exposing (Translations)

view : Translations -> OpeningHours -> Html msg
view i18n hours =
    case hours of
        Open247 ->
            div [ class "flex items-center gap-2" ]
                [ span [ class "font-bold type-body" ] [ text i18n.alwaysOpen ]
                , span [ class "text-text-muted type-body-small" ] [ text i18n.alwaysOpen ]
                ]
        Rules rules ->
            div [ class "flex flex-col gap-1" ]
                (List.map (viewRule i18n) rules)

viewRule : Translations -> Rule -> Html msg
viewRule i18n rule =
    let
        daysText =
            case rule.days of
                Just days -> formatDaySelectors i18n days
                Nothing -> i18n.everyDay
        
        statusNode =
            case rule.status of
                Off -> span [ class "text-brand-red font-medium type-body" ] [ text i18n.closed ]
                Open times -> span [ class "text-text-muted type-body" ] [ text (formatTimeSpans i18n times) ]
    in
    div [ class "flex gap-2 items-baseline" ]
        [ span [ class "font-medium w-32 shrink-0 type-body text-text-primary" ] [ text daysText ]
        , statusNode
        ]

formatDaySelectors : Translations -> List DaySelector -> String
formatDaySelectors i18n selectors =
    selectors
        |> List.map (formatDaySelector i18n)
        |> String.join ", "

formatDaySelector : Translations -> DaySelector -> String
formatDaySelector i18n sel =
    case sel of
        SingleDay d -> dayToString i18n d
        DayRange start end -> dayToString i18n start ++ " - " ++ dayToString i18n end
        PublicHoliday -> i18n.publicHolidays

dayToString : Translations -> Day -> String
dayToString i18n d =
    case d of
        Mo -> i18n.monday
        Tu -> i18n.tuesday
        We -> i18n.wednesday
        Th -> i18n.thursday
        Fr -> i18n.friday
        Sa -> i18n.saturday
        Su -> i18n.sunday

formatTimeSpans : Translations -> List TimeSpan -> String
formatTimeSpans i18n spans =
    spans
        |> List.map (formatTimeSpan i18n)
        |> String.join ", "

formatTimeSpan : Translations -> TimeSpan -> String
formatTimeSpan i18n span =
    case span of
        TimeRange start end -> formatTime start ++ " - " ++ formatTime end
        OpenEnded start -> formatTime start ++ i18n.onwards

formatTime : Time -> String
formatTime t =
    String.padLeft 2 '0' (String.fromInt t.hour) ++ "." ++ String.padLeft 2 '0' (String.fromInt t.minute)

formatToString : Translations -> OpeningHours -> String
formatToString i18n hours =
    case hours of
        Open247 ->
            i18n.alwaysOpen
        Rules rules ->
            rules
                |> List.map (formatRuleToString i18n)
                |> String.join "\n"

formatRuleToString : Translations -> Rule -> String
formatRuleToString i18n rule =
    let
        daysText =
            case rule.days of
                Just days -> formatDaySelectors i18n days
                Nothing -> i18n.everyDay
        
        statusText =
            case rule.status of
                Off -> i18n.closed
                Open times -> formatTimeSpans i18n times
    in
    daysText ++ ": " ++ statusText
