module LoadStateTest exposing (suite)

{-| Test suite for Component.LoadState.
-}

import Component.LoadState as LoadState
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.LoadState"
        [ test "loading renders role='status'" <|
            \_ ->
                LoadState.view
                    { loadingLabel = "Ladataan tietoja..."
                    , errorMessage = \_ -> "Virhe"
                    , onRetry = Nothing
                    , retryLabel = "Yritä uudelleen"
                    }
                    LoadState.Loading
                    (\_ -> Html.text "Valmis")
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Attr.attribute "role" "status") ]
        , test "failure renders the Alert text" <|
            \_ ->
                LoadState.view
                    { loadingLabel = "Ladataan..."
                    , errorMessage = \err -> "Lataus epäonnistui: " ++ err
                    , onRetry = Nothing
                    , retryLabel = "Yritä uudelleen"
                    }
                    (LoadState.Failure "Verkkovirhe")
                    (\_ -> Html.text "Valmis")
                    |> Query.fromHtml
                    |> Query.has [ Selector.containing [ Selector.text "Lataus epäonnistui: Verkkovirhe" ] ]
        , test "success renders the callback" <|
            \_ ->
                LoadState.view
                    { loadingLabel = "Ladataan..."
                    , errorMessage = \_ -> "Virhe"
                    , onRetry = Nothing
                    , retryLabel = "Yritä uudelleen"
                    }
                    (LoadState.Success "Sisältö")
                    (\content -> Html.div [] [ Html.text content ])
                    |> Query.fromHtml
                    |> Query.has [ Selector.containing [ Selector.text "Sisältö" ] ]
        ]
