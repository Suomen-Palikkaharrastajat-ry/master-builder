module Component.Timeline exposing (view, viewItem)

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr


view : List (Html msg) -> Html msg
view items =
    Html.ol
        [ Attr.class "not-prose relative border-s border-border-default space-y-0" ]
        items


viewItem : { date : String, title : String, icon : Maybe FeatherIcons.Icon, children : List (Html msg) } -> Html msg
viewItem config =
    Html.li
        [ Attr.class "mb-10 ms-6" ]
        [ Html.span
            [ Attr.class "absolute -start-3 flex h-6 w-6 items-center justify-center rounded-full bg-brand-yellow ring-4 ring-white text-brand" ]
            [ case config.icon of
                Just icon ->
                    icon
                        |> FeatherIcons.withSize 14
                        |> FeatherIcons.withStrokeWidth 2.5
                        |> FeatherIcons.toHtml []

                Nothing ->
                    Html.span [ Attr.class "h-2 w-2 rounded-full bg-brand" ] []
            ]
        , Html.time
            [ Attr.class "mb-1 block text-xs font-semibold uppercase tracking-wider leading-none text-text-muted" ]
            [ Html.text config.date ]
        , Html.h3
            [ Attr.class "text-sm font-semibold text-brand" ]
            [ Html.text config.title ]
        , Html.div
            [ Attr.class "mt-1 text-sm leading-6 text-text-muted" ]
            config.children
        ]
