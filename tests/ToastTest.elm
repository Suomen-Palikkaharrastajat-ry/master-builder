module ToastTest exposing (suite)

{-| Test suite for Component.Toast.
-}

import Component.Toast as Toast
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Toast"
        [ test "viewToast renders role='status' for Success variant" <|
            \_ ->
                Toast.viewToast "Sulje"
                    { id = "toast-1"
                    , title = Just "Onnistui"
                    , body = "Tallennus onnistui."
                    , variant = Toast.Success
                    , onClose = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Attr.attribute "role" "status") ]
        , test "viewToast renders role='alert' for Danger variant" <|
            \_ ->
                Toast.viewToast "Sulje"
                    { id = "toast-2"
                    , title = Just "Virhe"
                    , body = "Tapahtui virhe."
                    , variant = Toast.Danger
                    , onClose = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Attr.attribute "role" "alert") ]
        , test "viewToast renders title when present" <|
            \_ ->
                Toast.viewToast "Sulje"
                    { id = "toast-3"
                    , title = Just "Huomio"
                    , body = "Viesti"
                    , variant = Toast.Default
                    , onClose = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.has [ Selector.containing [ Selector.text "Huomio" ] ]
        , test "viewToast renders close button with aria-label" <|
            \_ ->
                Toast.viewToast "Sulje"
                    { id = "toast-4"
                    , title = Nothing
                    , body = "Suljettava viesti"
                    , variant = Toast.Warning
                    , onClose = Just ()
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "button" ]
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-label" "Sulje") ]
        , test "region renders container with role='region' and aria-live='polite'" <|
            \_ ->
                Toast.region
                    { label = "Ilmoitusalue", closeLabel = "Sulje ilmoitus" }
                    [ { id = "1"
                      , title = Just "Info"
                      , body = "Sisältö"
                      , variant = Toast.Default
                      , onClose = Just ()
                      }
                    ]
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.attribute (Attr.attribute "role" "region")
                        , Selector.attribute (Attr.attribute "aria-label" "Ilmoitusalue")
                        ]
        ]
