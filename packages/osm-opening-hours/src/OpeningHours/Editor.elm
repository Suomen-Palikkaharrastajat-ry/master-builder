module OpeningHours.Editor exposing (Model, Msg, init, update, view, getRawString)

import Html exposing (Html, div, input, text, label)
import Html.Attributes exposing (class, type_, value, placeholder, for, id)
import Html.Events exposing (onInput)
import OpeningHours.Parser exposing (parse)
import OpeningHours.ErrorFormatter as ErrorFormatter
import OpeningHours.Viewer as Viewer
import OpeningHours.I18n exposing (Translations)

type alias Model =
    { rawInput : String }

type Msg
    = InputChanged String

init : String -> Model
init initial =
    { rawInput = initial }

update : Msg -> Model -> Model
update (InputChanged str) model =
    { model | rawInput = str }

getRawString : Model -> String
getRawString model =
    model.rawInput

view : Translations -> Model -> Html Msg
view i18n model =
    let
        parsed = parse model.rawInput
    in
    div [ class "flex flex-col gap-2 w-full" ]
        [ label [ for "opening-hours-input", class "type-body-small font-medium text-text-primary" ] 
            [ text i18n.editorLabel ]
        , input 
            [ id "opening-hours-input"
            , type_ "text"
            , value model.rawInput
            , onInput InputChanged
            , placeholder i18n.editorPlaceholder
            , class "w-full p-2 border border-border-default rounded focus-visible:ring-2 focus-visible:ring-brand outline-none type-body"
            ] []
        , case parsed of
            Ok hours ->
                div [ class "p-3 bg-bg-subtle border border-border-default rounded mt-1" ]
                    [ Viewer.view i18n hours ]
            Err deadEnds ->
                if String.trim model.rawInput == "" then
                    div [ class "type-body-small text-text-muted mt-1" ] 
                        [ text i18n.editorHelpText ]
                else
                    div [ class "flex flex-col gap-1 p-3 bg-[#FEF2F2] text-brand-red border border-[#FCA5A5] rounded type-body-small mt-1" ]
                        [ div [ class "font-bold" ] [ text (ErrorFormatter.toHelpfulMessage i18n deadEnds) ]
                        , div [ class "opacity-90" ] [ text i18n.editorHelpText ]
                        ]
        ]
