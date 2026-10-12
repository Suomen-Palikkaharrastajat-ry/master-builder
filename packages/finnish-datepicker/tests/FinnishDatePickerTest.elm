module FinnishDatePickerTest exposing (suite)

{-| Test suite for FinnishDatePicker module.
-}

import DatePicker
import Expect
import FinnishDatePicker
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import TestLocale


suite : Test
suite =
    describe "FinnishDatePicker"
        [ describe "field"
            [ test "associates label for with input id" <|
                \_ ->
                    let
                        ( initPicker, _ ) =
                            DatePicker.init
                    in
                    FinnishDatePicker.field TestLocale.fi
                        (FinnishDatePicker.defaultField "birth-date" "Syntymäaika")
                        { picker = initPicker
                        , selectedIsoDate = "2026-02-01"
                        , onMsg = \_ -> ()
                        }
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "label"
                            , Selector.attribute (Attr.for "birth-date")
                            , Selector.containing [ Selector.text "Syntymäaika" ]
                            ]
            , test "renders aria-describedby, aria-invalid, and aria-required on input" <|
                \_ ->
                    let
                        ( initPicker, _ ) =
                            DatePicker.init

                        fieldConfig =
                            { id = "event-date"
                            , label = "Tapahtumapäivä"
                            , labelHidden = False
                            , hint = Just "Valitse kalenterista"
                            , error = Just "Päivämäärä on pakollinen"
                            , required = True
                            , disabled = False
                            }
                    in
                    FinnishDatePicker.field TestLocale.fi
                        fieldConfig
                        { picker = initPicker
                        , selectedIsoDate = ""
                        , onMsg = \_ -> ()
                        }
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "input" ]
                        |> Query.has
                            [ Selector.attribute (Attr.attribute "aria-describedby" "event-date-hint event-date-error")
                            , Selector.attribute (Attr.attribute "aria-invalid" "true")
                            , Selector.attribute (Attr.attribute "aria-required" "true")
                            , Selector.attribute (Attr.required True)
                            ]
            , test "renders disabled attribute when field.disabled is True" <|
                \_ ->
                    let
                        ( initPicker, _ ) =
                            DatePicker.init

                        fieldConfig =
                            { id = "disabled-date"
                            , label = "Lukittu päivä"
                            , labelHidden = False
                            , hint = Nothing
                            , error = Nothing
                            , required = False
                            , disabled = True
                            }
                    in
                    FinnishDatePicker.field TestLocale.fi
                        fieldConfig
                        { picker = initPicker
                        , selectedIsoDate = ""
                        , onMsg = \_ -> ()
                        }
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "input" ]
                        |> Query.has
                            [ Selector.attribute (Attr.disabled True)
                            ]
            ]
        , describe "update"
            [ test "updates picker without crash" <|
                \_ ->
                    let
                        ( initPicker, _ ) =
                            DatePicker.init

                        ( updatedPicker, maybeIso ) =
                            FinnishDatePicker.update TestLocale.fi DatePicker.open initPicker
                    in
                    maybeIso
                        |> Expect.equal Nothing
            ]
        ]
