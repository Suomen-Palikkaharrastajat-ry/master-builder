module Component.Toggle exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view :
    { id : String
    , label : String
    , checked : Bool
    , onToggle : Bool -> msg
    , disabled : Bool
    }
    -> Html msg
view config =
    Html.label
        [ Attr.for config.id
        , Attr.class
            ("inline-flex items-center gap-3 cursor-pointer "
                ++ (if config.disabled then
                        "opacity-40 cursor-not-allowed"

                    else
                        ""
                   )
            )
        ]
        [ Html.input
            [ Attr.type_ "checkbox"
            , Attr.id config.id
            , Attr.checked config.checked
            , Attr.disabled config.disabled
            , Attr.class "sr-only peer"
            , Attr.attribute "role" "switch"
            , Attr.attribute "aria-checked"
                (if config.checked then
                    "true"

                 else
                    "false"
                )
            , Events.onCheck config.onToggle
            ]
            []
        , Html.span
            [ Attr.class "relative w-10 h-6 rounded-full border-2 transition-colors duration-200 peer-focus-visible:ring-2 peer-focus-visible:ring-brand peer-focus-visible:ring-offset-2 peer-checked:bg-brand peer-checked:border-brand bg-white border-gray-300 after:absolute after:top-0.5 after:left-0.5 after:h-4 after:w-4 after:rounded-full after:bg-current after:transition-transform after:duration-200 peer-checked:after:translate-x-4 text-gray-300 peer-checked:text-white" ]
            []
        , Html.span [ Attr.class "text-sm font-medium text-text-primary select-none" ]
            [ Html.text config.label ]
        ]
