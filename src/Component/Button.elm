module Component.Button exposing (Config, Size(..), Variant(..), view, viewLink)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


type Variant
    = Primary
    | Secondary
    | Ghost
    | Danger


type Size
    = Sm
    | Md
    | Lg


type alias Config msg =
    { label : String
    , variant : Variant
    , size : Size
    , onClick : msg
    , disabled : Bool
    , loading : Bool
    , ariaPressedState : Maybe Bool
    }


view : Config msg -> Html msg
view config =
    Html.button
        ([ Attr.class (baseClasses config.size config.variant)
         , Attr.disabled (config.disabled || config.loading)
         , Events.onClick config.onClick
         ]
            ++ (case config.ariaPressedState of
                    Just pressed ->
                        [ Attr.attribute "aria-pressed"
                            (if pressed then
                                "true"

                             else
                                "false"
                            )
                        ]

                    Nothing ->
                        []
               )
        )
        [ if config.loading then
            Html.span [ Attr.class "inline-block animate-spin mr-2" ] [ Html.text "⟳" ]

          else
            Html.text ""
        , Html.text config.label
        ]


viewLink : { label : String, href : String, variant : Variant, size : Size } -> Html msg
viewLink config =
    Html.a
        [ Attr.href config.href
        , Attr.class (baseClasses config.size config.variant)
        ]
        [ Html.text config.label ]


baseClasses : Size -> Variant -> String
baseClasses size variant =
    String.join " "
        [ "inline-flex items-center justify-center font-semibold rounded-lg transition-colors focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        , sizeClasses size
        , variantClasses variant
        ]


sizeClasses : Size -> String
sizeClasses size =
    case size of
        Sm ->
            "px-3 py-1.5 text-sm"

        Md ->
            "px-4 py-2 text-sm"

        Lg ->
            "px-6 py-3 text-base"


variantClasses : Variant -> String
variantClasses variant =
    case variant of
        Primary ->
            "bg-brand-yellow text-brand hover:opacity-90 focus-visible:ring-brand"

        Secondary ->
            "bg-white text-brand border border-gray-300 font-semibold hover:bg-gray-50 focus-visible:ring-brand"

        Ghost ->
            "text-brand hover:bg-gray-100 focus-visible:ring-brand"

        Danger ->
            "bg-red-600 text-white hover:bg-red-700 focus-visible:ring-red-500"
