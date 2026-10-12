module ScrollToTopTest exposing (suite)

{-| Test suite for Component.ScrollToTop.
-}

import Component.ScrollToTop as ScrollToTop
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.ScrollToTop"
        [ test "renders nothing when visible is False" <|
            \_ ->
                ScrollToTop.view
                    { visible = False
                    , onClick = ()
                    , label = "Siirry sivun alkuun"
                    , clearRightColumn = False
                    }
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.tag "button" ]
        , test "renders button with aria-label when visible is True" <|
            \_ ->
                ScrollToTop.view
                    { visible = True
                    , onClick = ()
                    , label = "Siirry sivun alkuun"
                    , clearRightColumn = True
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "button"
                        , Selector.attribute (Attr.type_ "button")
                        , Selector.attribute (Attr.attribute "aria-label" "Siirry sivun alkuun")
                        ]
        ]
