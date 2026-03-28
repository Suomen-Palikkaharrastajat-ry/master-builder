module Component.FeatureGrid exposing (Feature, view)

import Html exposing (Html)
import Html.Attributes as Attr


type alias Feature msg =
    { icon : Maybe String
    , title : String
    , description : List (Html msg)
    }


view : { columns : Int, features : List (Feature msg) } -> Html msg
view config =
    Html.div
        [ Attr.class "py-12" ]
        [ Html.div
            [ Attr.class (gridClasses config.columns) ]
            (List.map viewFeature config.features)
        ]


viewFeature : Feature msg -> Html msg
viewFeature feature =
    Html.div
        [ Attr.class "flex flex-col" ]
        [ case feature.icon of
            Just ico ->
                Html.div
                    [ Attr.class "mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-brand-yellow text-brand type-h4" ]
                    [ Html.text ico ]

            Nothing ->
                Html.text ""
        , Html.h3
            [ Attr.class "type-h4 leading-7 text-text-primary" ]
            [ Html.text feature.title ]
        , Html.div
            [ Attr.class "mt-2 type-caption leading-7 text-text-muted" ]
            feature.description
        ]


gridClasses : Int -> String
gridClasses columns =
    "grid gap-x-8 gap-y-10 "
        ++ (case columns of
                2 ->
                    "sm:grid-cols-2"

                3 ->
                    "sm:grid-cols-2 lg:grid-cols-3"

                4 ->
                    "sm:grid-cols-2 lg:grid-cols-4"

                _ ->
                    "sm:grid-cols-2 lg:grid-cols-3"
           )
