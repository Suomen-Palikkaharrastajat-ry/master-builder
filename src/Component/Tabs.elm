module Component.Tabs exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view : { tabs : List String, activeIndex : Int, onTabClick : Int -> msg } -> Html msg
view config =
    Html.div
        [ Attr.attribute "role" "tablist"
        , Attr.class "flex gap-1 border-b border-border-default"
        ]
        (List.indexedMap (viewTab config) config.tabs)


viewTab : { tabs : List String, activeIndex : Int, onTabClick : Int -> msg } -> Int -> String -> Html msg
viewTab config index label =
    let
        isActive =
            index == config.activeIndex

        tabId =
            "tab-" ++ String.fromInt index

        panelId =
            "tabpanel-" ++ String.fromInt index
    in
    Html.button
        [ Attr.id tabId
        , Attr.attribute "role" "tab"
        , Attr.attribute "aria-selected"
            (if isActive then
                "true"

             else
                "false"
            )
        , Attr.attribute "aria-controls" panelId
        , Events.onClick (config.onTabClick index)
        , Attr.class
            ("px-4 py-2 text-sm font-medium transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 rounded-t cursor-pointer -mb-px border-b-2 "
                ++ (if isActive then
                        "border-brand text-text-primary"

                    else
                        "border-transparent text-text-muted hover:text-text-primary"
                   )
            )
        ]
        [ Html.text label ]
