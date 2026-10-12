module FinnishDatePicker exposing (Field, defaultField, field, update, view)

{-| Date picker component configured with Finnish localization and design-system styling.

Wraps `CurrySoftware/elm-datepicker` with Finnish defaults (`pp.kk.vvvv`, Monday first,
Finnish weekday/month names) and accessible form field wrappers.

@docs Field, defaultField, field, update, view

-}

import Date exposing (Date)
import DatePicker exposing (DateEvent(..), InputError(..), defaultSettings)
import FinnishDate
import Html exposing (Html)
import Html.Attributes as Attr
import Time exposing (Weekday(..))


{-| Form field configuration for `field`. Compatible with `Component.Form.Field`.
-}
type alias Field =
    { id : String
    , label : String
    , labelHidden : Bool
    , hint : Maybe String
    , error : Maybe String
    , required : Bool
    , disabled : Bool
    }


{-| Creates a default `Field` configuration with standard defaults.
-}
defaultField : String -> String -> Field
defaultField id label =
    { id = id
    , label = label
    , labelHidden = False
    , hint = Nothing
    , error = Nothing
    , required = False
    , disabled = False
    }


{-| Renders the raw date picker with an input ID.
-}
view :
    { picker : DatePicker.DatePicker
    , selectedIsoDate : String
    , inputId : String
    }
    -> Html DatePicker.Msg
view config =
    DatePicker.view
        (isoDateToDate config.selectedIsoDate)
        (defaultSettingsWithInputId (Just config.inputId))
        config.picker


{-| Accessible form field wrapper containing label, date picker input, hint, and error messaging.
-}
field :
    Field
    ->
        { picker : DatePicker.DatePicker
        , selectedIsoDate : String
        , onMsg : DatePicker.Msg -> msg
        }
    -> Html msg
field f config =
    let
        pickerHtml =
            DatePicker.view
                (isoDateToDate config.selectedIsoDate)
                (fieldSettings f)
                config.picker
                |> Html.map config.onMsg
    in
    Html.div
        [ Attr.class "mb-4" ]
        [ viewLabel f
        , pickerHtml
        , viewHint f
        , viewError f
        ]


{-| Handles date picker messages, returning the updated picker state and optional picked ISO date.
-}
update : DatePicker.Msg -> DatePicker.DatePicker -> ( DatePicker.DatePicker, Maybe String )
update datePickerMsg picker =
    let
        ( updatedPicker, dateEvent ) =
            DatePicker.update (defaultSettingsWithInputId Nothing) datePickerMsg picker
    in
    ( updatedPicker, dateEventToIso dateEvent )


fieldSettings : Field -> DatePicker.Settings
fieldSettings f =
    let
        hasError =
            f.error /= Nothing

        describedBy =
            case ( f.hint, f.error ) of
                ( Just _, Just _ ) ->
                    Just (f.id ++ "-hint " ++ f.id ++ "-error")

                ( Just _, Nothing ) ->
                    Just (f.id ++ "-hint")

                ( Nothing, Just _ ) ->
                    Just (f.id ++ "-error")

                ( Nothing, Nothing ) ->
                    Nothing

        describedByAttrs =
            case describedBy of
                Just ids ->
                    [ Attr.attribute "aria-describedby" ids ]

                Nothing ->
                    []

        invalidAttrs =
            if hasError then
                [ Attr.attribute "aria-invalid" "true" ]

            else
                []

        requiredAttrs =
            if f.required then
                [ Attr.required True
                , Attr.attribute "aria-required" "true"
                ]

            else
                []

        disabledAttrs =
            if f.disabled then
                [ Attr.disabled True ]

            else
                []
    in
    { defaultSettings
        | placeholder = "pp.kk.vvvv"
        , inputId = Just f.id
        , inputAttributes =
            describedByAttrs ++ invalidAttrs ++ requiredAttrs ++ disabledAttrs
        , inputClassList =
            [ ( "w-full", True )
            , ( "rounded", True )
            , ( "border", True )
            , ( "border-border-brand", not hasError )
            , ( "border-brand-red", hasError )
            , ( "bg-bg-page", True )
            , ( "px-3", True )
            , ( "py-2", True )
            , ( "type-body-small", True )
            , ( "focus-visible:outline-none", True )
            , ( "focus-visible:ring-2", True )
            , ( "focus-visible:ring-brand", True )
            , ( "opacity-50 cursor-not-allowed", f.disabled )
            ]
        , parser = FinnishDate.parse
        , dateFormatter = FinnishDate.format
        , dayFormatter = FinnishDate.weekdayAbbr
        , monthFormatter =
            \month ->
                FinnishDate.monthName (FinnishDate.monthToInt month)
        , firstDayOfWeek = Mon
    }


defaultSettingsWithInputId : Maybe String -> DatePicker.Settings
defaultSettingsWithInputId maybeInputId =
    { defaultSettings
        | placeholder = "pp.kk.vvvv"
        , inputId = maybeInputId
        , inputClassList =
            [ ( "w-full", True )
            , ( "rounded", True )
            , ( "border", True )
            , ( "border-border-default", True )
            , ( "bg-bg-page", True )
            , ( "px-3", True )
            , ( "py-2", True )
            , ( "type-body-small", True )
            , ( "focus-visible:outline-none", True )
            , ( "focus-visible:ring-2", True )
            , ( "focus-visible:ring-brand", True )
            ]
        , parser = FinnishDate.parse
        , dateFormatter = FinnishDate.format
        , dayFormatter = FinnishDate.weekdayAbbr
        , monthFormatter =
            \month ->
                FinnishDate.monthName (FinnishDate.monthToInt month)
        , firstDayOfWeek = Mon
    }


dateEventToIso : DatePicker.DateEvent -> Maybe String
dateEventToIso dateEvent =
    case dateEvent of
        Picked date ->
            Just (Date.toIsoString date)

        FailedInput EmptyString ->
            Just ""

        _ ->
            Nothing


isoDateToDate : String -> Maybe Date
isoDateToDate isoDate =
    case Date.fromIsoString isoDate of
        Ok date ->
            Just date

        Err _ ->
            Nothing


viewLabel : Field -> Html msg
viewLabel f =
    Html.label
        [ Attr.for f.id
        , Attr.class
            (if f.labelHidden then
                "sr-only"

             else
                "type-body-small block mb-1 text-text-primary"
            )
        ]
        (if f.required then
            [ Html.text f.label
            , Html.text " "
            , Html.span
                [ Attr.attribute "aria-hidden" "true"
                , Attr.class "text-brand-red"
                ]
                [ Html.text "*" ]
            ]

         else
            [ Html.text f.label ]
        )


viewHint : Field -> Html msg
viewHint f =
    case f.hint of
        Just hintText ->
            Html.p
                [ Attr.id (f.id ++ "-hint")
                , Attr.class "type-caption text-text-muted mt-1"
                ]
                [ Html.text hintText ]

        Nothing ->
            Html.text ""


viewError : Field -> Html msg
viewError f =
    case f.error of
        Just errorText ->
            Html.p
                [ Attr.id (f.id ++ "-error")
                , Attr.attribute "role" "alert"
                , Attr.class "type-caption text-brand-red mt-1"
                ]
                [ Html.text errorText ]

        Nothing ->
            Html.text ""
