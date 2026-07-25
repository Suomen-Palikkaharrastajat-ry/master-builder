module OpeningHours.ErrorFormatter exposing (toHelpfulMessage)

import Parser exposing (DeadEnd, Problem(..))
import OpeningHours.I18n exposing (Translations)

toHelpfulMessage : Translations -> List DeadEnd -> String
toHelpfulMessage i18n deadEnds =
    case List.head deadEnds of
        Just deadEnd ->
            case deadEnd.problem of
                ExpectingSymbol "-" ->
                    i18n.errMissingDash
                ExpectingSymbol ":" ->
                    i18n.errMissingColon
                ExpectingSymbol "+" ->
                    i18n.errMissingPlus
                Expecting keyword ->
                    i18n.errExpectedKeyword
                ExpectingEnd ->
                    i18n.errExtraText
                Problem "empty days" ->
                    i18n.errEmptyDays
                Problem "empty times" ->
                    i18n.errEmptyTimes
                Problem "invalid int" ->
                    i18n.errInvalidInt
                _ ->
                    i18n.errSyntax
        Nothing ->
            i18n.errUnknown
