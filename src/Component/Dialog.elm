module Component.Dialog exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


view :
    { title : String
    , body : List (Html msg)
    , footer : Maybe (Html msg)
    , isOpen : Bool
    , onClose : msg
    }
    -> Html msg
view config =
    if not config.isOpen then
        Html.text ""

    else
        Html.div
            [ Attr.class "fixed inset-0 z-50 flex items-center justify-center p-4"
            , Attr.attribute "role" "dialog"
            , Attr.attribute "aria-modal" "true"
            , Attr.attribute "aria-labelledby" "dialog-title"
            ]
            [ -- backdrop
              Html.div
                [ Attr.class "absolute inset-0 bg-black/50"
                , Events.onClick config.onClose
                ]
                []
            , -- panel
              Html.div
                [ Attr.class "relative z-10 w-full max-w-lg bg-white rounded-xl shadow-lg overflow-hidden" ]
                [ Html.div
                    [ Attr.class "flex items-center justify-between px-6 py-4 border-b border-border-default" ]
                    [ Html.h2
                        [ Attr.id "dialog-title"
                        , Attr.class "text-lg font-semibold text-text-primary"
                        ]
                        [ Html.text config.title ]
                    , Html.button
                        [ Events.onClick config.onClose
                        , Attr.attribute "aria-label" "Sulje"
                        , Attr.class "inline-flex items-center justify-center w-8 h-8 rounded text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2 cursor-pointer"
                        ]
                        [ Html.text "✕" ]
                    ]
                , Html.div
                    [ Attr.class "px-6 py-4 text-sm text-text-muted" ]
                    config.body
                , case config.footer of
                    Just footer ->
                        Html.div
                            [ Attr.class "px-6 py-4 border-t border-border-default bg-bg-subtle flex justify-end gap-3" ]
                            [ footer ]

                    Nothing ->
                        Html.text ""
                ]
            ]
