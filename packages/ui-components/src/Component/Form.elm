module Component.Form exposing (Field, TextType(..), Layout(..), defaultField, textInput, textarea, checkbox, radioGroup, fileInput, fieldRow)

{-| Form field components with accessible labels, hints, and error messaging.

@docs Field, TextType, Layout, defaultField, textInput, textarea, checkbox, radioGroup, fileInput, fieldRow

-}

import File exposing (File)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Common configuration for all form fields.
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


{-| HTML input type variant for text inputs.
-}
type TextType
    = Text
    | Email
    | Url
    | Search
    | Tel
    | Number { step : String }
    | Time


{-| Visual arrangement layout for radio groups.
-}
type Layout
    = Inline
    | Chips


{-| Creates a default `Field` with standard defaults (optional, enabled, visible label).
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


{-| Single-line text input with associated label, hint, and error.
-}
textInput :
    Field
    ->
        { value : String
        , onInput : String -> msg
        , inputType : TextType
        , placeholder : Maybe String
        }
    -> Html msg
textInput field config =
    Html.div
        [ classes [ Tw.mb Th.s4 ] ]
        [ viewLabel field
        , Html.input
            ([ textTypeAttr config.inputType
             , Attr.id field.id
             , Attr.value config.value
             , Events.onInput config.onInput
             , Attr.disabled field.disabled
             , classes (inputClasses field.error)
             ]
                ++ (case config.placeholder of
                        Just ph ->
                            [ Attr.placeholder ph ]

                        Nothing ->
                            []
                   )
                ++ textTypeExtraAttrs config.inputType
                ++ ariaAttributes field
            )
            []
        , viewHint field
        , viewError field
        ]


{-| Multi-line text area input.
-}
textarea :
    Field
    ->
        { value : String
        , onInput : String -> msg
        , rows : Int
        }
    -> Html msg
textarea field config =
    Html.div
        [ classes [ Tw.mb Th.s4 ] ]
        [ viewLabel field
        , Html.textarea
            ([ Attr.id field.id
             , Attr.value config.value
             , Events.onInput config.onInput
             , Attr.rows config.rows
             , Attr.disabled field.disabled
             , classes (inputClasses field.error)
             ]
                ++ ariaAttributes field
            )
            []
        , viewHint field
        , viewError field
        ]


{-| Checkbox input with accessible label.
-}
checkbox :
    Field
    ->
        { checked : Bool
        , onCheck : Bool -> msg
        }
    -> Html msg
checkbox field config =
    Html.div
        [ classes [ Tw.mb Th.s4 ] ]
        [ Html.div
            [ classes [ Tw.flex, Tw.items_center, Tw.gap Th.s2 ] ]
            [ Html.input
                ([ Attr.type_ "checkbox"
                 , Attr.id field.id
                 , Attr.checked config.checked
                 , Events.onCheck config.onCheck
                 , Attr.disabled field.disabled
                 , classes
                    [ Tw.rounded
                    , Tw.border
                    , case field.error of
                        Just _ ->
                            Tw.border_simple TC.brandRed

                        Nothing ->
                            Tw.border_simple TC.borderDefault
                    , Tw.text_simple TC.brand
                    , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                    ]
                 ]
                    ++ ariaAttributes field
                )
                []
            , viewLabelInline field
            ]
        , viewHint field
        , viewError field
        ]


{-| Group of radio buttons inside an accessible `<fieldset>` with `<legend>`.
-}
radioGroup :
    { legend : String
    , name : String
    , required : Bool
    , error : Maybe String
    }
    ->
        { options : List { value : String, label : String }
        , selected : String
        , onSelect : String -> msg
        , layout : Layout
        }
    -> Html msg
radioGroup groupConfig optionsConfig =
    let
        errorId =
            groupConfig.name ++ "-error"

        describedByAttr =
            case groupConfig.error of
                Just _ ->
                    [ Attr.attribute "aria-describedby" errorId ]

                Nothing ->
                    []

        invalidAttr =
            case groupConfig.error of
                Just _ ->
                    [ Attr.attribute "aria-invalid" "true" ]

                Nothing ->
                    []

        requiredAttr =
            if groupConfig.required then
                [ Attr.required True
                , Attr.attribute "aria-required" "true"
                ]

            else
                []
    in
    Html.fieldset
        [ classes [ Tw.mb Th.s4 ] ]
        [ Html.legend
            [ classes [ TwEx.type_body_small, Tw.block, Tw.mb Th.s2, Tw.text_simple TC.textPrimary ] ]
            (if groupConfig.required then
                [ Html.text groupConfig.legend
                , Html.text " "
                , Html.span
                    [ Attr.attribute "aria-hidden" "true"
                    , classes [ Tw.text_simple TC.brandRed ]
                    ]
                    [ Html.text "*" ]
                ]

             else
                [ Html.text groupConfig.legend ]
            )
        , Html.div
            [ classes
                (case optionsConfig.layout of
                    Inline ->
                        [ Tw.flex, Tw.flex_wrap, Tw.gap Th.s4 ]

                    Chips ->
                        [ Tw.flex, Tw.flex_wrap, Tw.gap Th.s3 ]
                )
            ]
            (List.map
                (\opt ->
                    let
                        optId =
                            groupConfig.name ++ "-" ++ opt.value

                        isSelected =
                            opt.value == optionsConfig.selected
                    in
                    case optionsConfig.layout of
                        Chips ->
                            Html.label
                                [ Attr.for optId
                                , classes
                                    [ Tw.inline_flex
                                    , Tw.items_center
                                    , Tw.gap Th.s2
                                    , Tw.border
                                    , if isSelected then
                                        Tw.border_simple TC.brand

                                      else
                                        Tw.border_simple TC.borderDefault
                                    , Tw.rounded
                                    , Tw.px Th.s3
                                    , Tw.py Th.s2
                                    , TwEx.type_caption
                                    , Tw.cursor_pointer
                                    ]
                                ]
                                [ Html.input
                                    ([ Attr.type_ "radio"
                                     , Attr.id optId
                                     , Attr.name groupConfig.name
                                     , Attr.value opt.value
                                     , Attr.checked isSelected
                                     , Events.onClick (optionsConfig.onSelect opt.value)
                                     ]
                                        ++ describedByAttr
                                        ++ invalidAttr
                                        ++ requiredAttr
                                    )
                                    []
                                , Html.text opt.label
                                ]

                        Inline ->
                            Html.label
                                [ Attr.for optId
                                , classes
                                    [ Tw.inline_flex
                                    , Tw.items_center
                                    , Tw.gap Th.s2
                                    , TwEx.type_body_small
                                    , Tw.cursor_pointer
                                    ]
                                ]
                                [ Html.input
                                    ([ Attr.type_ "radio"
                                     , Attr.id optId
                                     , Attr.name groupConfig.name
                                     , Attr.value opt.value
                                     , Attr.checked isSelected
                                     , Events.onClick (optionsConfig.onSelect opt.value)
                                     ]
                                        ++ describedByAttr
                                        ++ invalidAttr
                                        ++ requiredAttr
                                    )
                                    []
                                , Html.text opt.label
                                ]
                )
                optionsConfig.options
            )
        , case groupConfig.error of
            Just err ->
                Html.p
                    [ Attr.id errorId
                    , Attr.attribute "role" "alert"
                    , classes [ TwEx.type_caption, Tw.text_simple TC.brandRed, Tw.mt Th.s1 ]
                    ]
                    [ Html.text err ]

            Nothing ->
                Html.text ""
        ]


{-| File upload input with optional preview.
-}
fileInput :
    Field
    ->
        { accept : String
        , onFile : File -> msg
        , preview : Maybe { src : String, alt : String }
        }
    -> Html msg
fileInput field config =
    Html.div
        [ classes [ Tw.mb Th.s4 ] ]
        [ viewLabel field
        , Html.input
            ([ Attr.type_ "file"
             , Attr.id field.id
             , Attr.accept config.accept
             , Events.on "change" (Decode.at [ "target", "files" ] (Decode.index 0 File.decoder) |> Decode.map config.onFile)
             , Attr.disabled field.disabled
             , classes (inputClasses field.error)
             ]
                ++ ariaAttributes field
            )
            []
        , case config.preview of
            Just prev ->
                Html.div
                    [ classes [ Tw.mt Th.s2 ] ]
                    [ Html.img
                        [ Attr.src prev.src
                        , Attr.alt prev.alt
                        , classes [ Tw.rounded, Tw.border, Tw.border_simple TC.borderDefault ]
                        ]
                        []
                    ]

            Nothing ->
                Html.text ""
        , viewHint field
        , viewError field
        ]


{-| Renders multiple fields in a flex row for date/time pairs.
-}
fieldRow : List (Html msg) -> Html msg
fieldRow fields =
    Html.div [ classes [ Tw.flex, Tw.gap Th.s2, Tw.flex_wrap ] ] fields


viewLabel : Field -> Html msg
viewLabel field =
    viewLabelWithMargin True field


viewLabelInline : Field -> Html msg
viewLabelInline field =
    viewLabelWithMargin False field


viewLabelWithMargin : Bool -> Field -> Html msg
viewLabelWithMargin withMargin field =
    Html.label
        [ Attr.for field.id
        , classes
            (if field.labelHidden then
                [ Tw.sr_only ]

             else if withMargin then
                [ TwEx.type_body_small
                , Tw.block
                , Tw.mb Th.s1
                , Tw.text_simple TC.textPrimary
                ]

             else
                [ TwEx.type_body_small
                , Tw.block
                , Tw.text_simple TC.textPrimary
                ]
            )
        ]
        (if field.required then
            [ Html.text field.label
            , Html.text " "
            , Html.span
                [ Attr.attribute "aria-hidden" "true"
                , classes [ Tw.text_simple TC.brandRed ]
                ]
                [ Html.text "*" ]
            ]

         else
            [ Html.text field.label ]
        )


viewHint : Field -> Html msg
viewHint field =
    case field.hint of
        Just hintText ->
            Html.p
                [ Attr.id (field.id ++ "-hint")
                , classes [ Tw.type_caption, Tw.text_simple TC.textMuted, Tw.mt Th.s1 ]
                ]
                [ Html.text hintText ]

        Nothing ->
            Html.text ""


viewError : Field -> Html msg
viewError field =
    case field.error of
        Just errorText ->
            Html.p
                [ Attr.id (field.id ++ "-error")
                , Attr.attribute "role" "alert"
                , classes [ Tw.type_caption, Tw.text_simple TC.brandRed, Tw.mt Th.s1 ]
                ]
                [ Html.text errorText ]

        Nothing ->
            Html.text ""


ariaAttributes : Field -> List (Html.Attribute msg)
ariaAttributes field =
    let
        describedBy =
            case ( field.hint, field.error ) of
                ( Just _, Just _ ) ->
                    Just (field.id ++ "-hint " ++ field.id ++ "-error")

                ( Just _, Nothing ) ->
                    Just (field.id ++ "-hint")

                ( Nothing, Just _ ) ->
                    Just (field.id ++ "-error")

                ( Nothing, Nothing ) ->
                    Nothing

        describedByAttr =
            case describedBy of
                Just ids ->
                    [ Attr.attribute "aria-describedby" ids ]

                Nothing ->
                    []

        invalidAttr =
            case field.error of
                Just _ ->
                    [ Attr.attribute "aria-invalid" "true" ]

                Nothing ->
                    []

        requiredAttrs =
            if field.required then
                [ Attr.required True
                , Attr.attribute "aria-required" "true"
                ]

            else
                []
    in
    describedByAttr ++ invalidAttr ++ requiredAttrs


inputClasses : Maybe String -> List Tw.Tailwind
inputClasses error =
    [ Tw.w_full
    , Tw.rounded
    , Tw.border
    , case error of
        Just _ ->
            Tw.border_simple TC.brandRed

        Nothing ->
            Tw.border_simple TC.borderDefault
    , Tw.bg_simple TC.bgPage
    , Tw.px Th.s3
    , Tw.py Th.s2
    , TwEx.type_body_small
    , Bp.focus_visible
        [ Tw.outline_none
        , Tw.ring_2
        , TwEx.ring_brand
        ]
    ]


textTypeAttr : TextType -> Html.Attribute msg
textTypeAttr textType =
    case textType of
        Text ->
            Attr.type_ "text"

        Email ->
            Attr.type_ "email"

        Url ->
            Attr.type_ "url"

        Search ->
            Attr.type_ "search"

        Tel ->
            Attr.type_ "tel"

        Number _ ->
            Attr.type_ "number"

        Time ->
            Attr.type_ "time"


textTypeExtraAttrs : TextType -> List (Html.Attribute msg)
textTypeExtraAttrs textType =
    case textType of
        Number { step } ->
            [ Attr.step step ]

        _ ->
            []
