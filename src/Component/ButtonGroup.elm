module Component.ButtonGroup exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : List (Html msg) -> Html msg
view buttons =
    Html.div
        [ Attr.class "inline-flex rounded-lg border border-gray-300 overflow-hidden divide-x divide-gray-300" ]
        (List.map viewButton buttons)


viewButton : Html msg -> Html msg
viewButton btn =
    Html.div
        [ Attr.class "first:rounded-l-lg last:rounded-r-lg [&>*]:rounded-none [&>*]:border-0" ]
        [ btn ]
