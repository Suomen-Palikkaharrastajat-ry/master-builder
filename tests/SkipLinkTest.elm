module SkipLinkTest exposing (suite)

{-| Test suite for Component.SkipLink.
-}

import Component.SkipLink as SkipLink
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.SkipLink"
        [ test "renders an anchor pointing to target with hash" <|
            \_ ->
                SkipLink.view { target = "main-content", label = "Hyppää pääsisältöön" }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "a"
                        , Selector.attribute (Attr.href "#main-content")
                        , Selector.containing [ Selector.text "Hyppää pääsisältöön" ]
                        ]
        ]
