module Component.DownloadButton exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { label : String, href : String } -> Html msg
view config =
    Html.a
        [ Attr.href config.href
        , Attr.download ""
        , Attr.class "inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg bg-brand-yellow text-brand hover:opacity-90 transition-opacity focus-visible:ring-2 focus-visible:ring-brand focus-visible:ring-offset-2"
        ]
        [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text "↓" ]
        , Html.text config.label
        ]
