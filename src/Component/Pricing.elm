module Component.Pricing exposing (Tier, view)

import Html exposing (Html)
import Html.Attributes as Attr


type alias Tier msg =
    { name : String
    , price : String
    , period : Maybe String
    , features : List String
    , cta : Html msg
    , highlighted : Bool
    }


view : List (Tier msg) -> Html msg
view tiers =
    Html.div
        [ Attr.class "py-12" ]
        [ Html.div
            [ Attr.class "grid gap-8 sm:grid-cols-2 lg:grid-cols-3" ]
            (List.map viewTier tiers)
        ]


viewTier : Tier msg -> Html msg
viewTier tier =
    Html.div
        [ Attr.class (tierClasses tier.highlighted) ]
        [ Html.div [ Attr.class "p-8" ]
            [ Html.h3
                [ Attr.class (tierNameClass tier.highlighted) ]
                [ Html.text tier.name ]
            , Html.div [ Attr.class "mt-4 flex items-baseline gap-x-2" ]
                [ Html.span
                    [ Attr.class (priceClass tier.highlighted) ]
                    [ Html.text tier.price ]
                , case tier.period of
                    Just p ->
                        Html.span
                            [ Attr.class (periodClass tier.highlighted) ]
                            [ Html.text ("/ " ++ p) ]

                    Nothing ->
                        Html.text ""
                ]
            , Html.ul
                [ Attr.class "mt-8 space-y-3" ]
                (List.map (viewFeature tier.highlighted) tier.features)
            , Html.div [ Attr.class "mt-8" ] [ tier.cta ]
            ]
        ]


viewFeature : Bool -> String -> Html msg
viewFeature highlighted feature =
    Html.li
        [ Attr.class "flex items-center gap-x-3 type-caption" ]
        [ Html.span
            [ Attr.class
                (if highlighted then
                    "text-white/70 type-h4"

                 else
                    "text-brand-yellow type-h4"
                )
            ]
            [ Html.text "✓" ]
        , Html.span
            [ Attr.class
                (if highlighted then
                    "text-white"

                 else
                    "text-text-primary"
                )
            ]
            [ Html.text feature ]
        ]


tierClasses : Bool -> String
tierClasses highlighted =
    "rounded-2xl border overflow-hidden "
        ++ (if highlighted then
                "bg-brand border-brand"

            else
                "bg-white border-border-default shadow-sm"
           )


tierNameClass : Bool -> String
tierNameClass highlighted =
    "type-h4 "
        ++ (if highlighted then
                "text-white"

            else
                "text-text-primary"
           )


priceClass : Bool -> String
priceClass highlighted =
    "type-display tracking-tight "
        ++ (if highlighted then
                "text-white"

            else
                "text-text-primary"
           )


periodClass : Bool -> String
periodClass highlighted =
    "type-body-small "
        ++ (if highlighted then
                "text-white/70"

            else
                "text-text-muted"
           )
