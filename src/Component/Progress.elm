module Component.Progress exposing (Color(..), view)

import Html exposing (Html)
import Html.Attributes as Attr


type Color
    = Brand
    | Success
    | Warning
    | Danger


view : { value : Int, max : Int, label : Maybe String, color : Color } -> Html msg
view config =
    let
        percentage =
            if config.max == 0 then
                0

            else
                clamp 0 100 (config.value * 100 // config.max)
    in
    Html.div [ Attr.class "w-full" ]
        [ case config.label of
            Just lbl ->
                Html.div
                    [ Attr.class "flex justify-between text-sm font-medium text-text-primary mb-1" ]
                    [ Html.span [] [ Html.text lbl ]
                    , Html.span [] [ Html.text (String.fromInt percentage ++ "%") ]
                    ]

            Nothing ->
                Html.text ""
        , Html.div
            [ Attr.class "w-full h-2 rounded-full bg-gray-200 overflow-hidden" ]
            [ Html.div
                [ Attr.class ("h-full rounded-full transition-all duration-300 " ++ colorClass config.color)
                , Attr.style "width" (String.fromInt percentage ++ "%")
                , Attr.attribute "role" "progressbar"
                , Attr.attribute "aria-valuenow" (String.fromInt config.value)
                , Attr.attribute "aria-valuemin" "0"
                , Attr.attribute "aria-valuemax" (String.fromInt config.max)
                ]
                []
            ]
        ]


colorClass : Color -> String
colorClass color =
    case color of
        Brand ->
            "bg-brand-yellow"

        Success ->
            "bg-green-500"

        Warning ->
            "bg-yellow-400"

        Danger ->
            "bg-brand-red"
