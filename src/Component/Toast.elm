module Component.Toast exposing (Variant(..), view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


type Variant
    = Default
    | Success
    | Warning
    | Danger


view :
    { title : String
    , body : String
    , variant : Variant
    , onClose : Maybe msg
    }
    -> Html msg
view config =
    Html.div
        [ Attr.class ("flex items-start gap-3 p-4 rounded-lg shadow-md border max-w-sm " ++ containerClass config.variant)
        , Attr.attribute "role" "alert"
        , Attr.attribute "aria-live" "assertive"
        ]
        [ Html.span
            [ Attr.class "text-lg leading-5 shrink-0"
            , Attr.attribute "aria-hidden" "true"
            ]
            [ Html.text (variantIcon config.variant) ]
        , Html.div [ Attr.class "flex-1 min-w-0" ]
            [ Html.p [ Attr.class ("text-sm font-semibold " ++ titleClass config.variant) ]
                [ Html.text config.title ]
            , if String.isEmpty config.body then
                Html.text ""

              else
                Html.p [ Attr.class ("text-sm mt-0.5 " ++ bodyClass config.variant) ]
                    [ Html.text config.body ]
            ]
        , case config.onClose of
            Just onClose ->
                Html.button
                    [ Events.onClick onClose
                    , Attr.attribute "aria-label" "Sulje ilmoitus"
                    , Attr.class "shrink-0 text-gray-400 hover:text-gray-600 transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 rounded cursor-pointer"
                    ]
                    [ Html.text "✕" ]

            Nothing ->
                Html.text ""
        ]


containerClass : Variant -> String
containerClass variant =
    case variant of
        Default ->
            "bg-white border-gray-200"

        Success ->
            "bg-green-50 border-green-200"

        Warning ->
            "bg-yellow-50 border-yellow-200"

        Danger ->
            "bg-red-50 border-red-200"


titleClass : Variant -> String
titleClass variant =
    case variant of
        Default ->
            "text-text-primary"

        Success ->
            "text-green-800"

        Warning ->
            "text-yellow-800"

        Danger ->
            "text-red-800"


bodyClass : Variant -> String
bodyClass variant =
    case variant of
        Default ->
            "text-text-muted"

        Success ->
            "text-green-700"

        Warning ->
            "text-yellow-700"

        Danger ->
            "text-red-700"


variantIcon : Variant -> String
variantIcon variant =
    case variant of
        Default ->
            "ℹ"

        Success ->
            "✓"

        Warning ->
            "⚠"

        Danger ->
            "✕"
