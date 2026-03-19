module Component.SectionHeader exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { title : String, description : Maybe String } -> Html msg
view config =
    Html.div [ Attr.class "mb-6" ]
        [ Html.h2
            [ Attr.class "text-2xl font-bold text-text-primary" ]
            [ Html.text config.title ]
        , case config.description of
            Just desc ->
                Html.p
                    [ Attr.class "mt-2 text-sm text-text-muted max-w-prose" ]
                    [ Html.text desc ]

            Nothing ->
                Html.text ""
        ]
