module FooterTest exposing (suite)

{-| Test suite for Component.Footer and Component.Footer.Family.
-}

import Component.Footer as Footer
import Component.Footer.Family as Family
import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Footer"
        [ test "Family.copyright formats year correctly" <|
            \_ ->
                Family.copyright 2026
                    |> String.contains "2026 Suomen Palikkaharrastajat ry"
                    |> Expect.equal True
        , test "Family.links contains canonical services" <|
            \_ ->
                Family.links
                    |> List.any (\l -> l.label == "Palikkakalenteri")
                    |> Expect.equal True
        , test "viewWith renders footer with extra content and copyright" <|
            \_ ->
                Footer.viewWith
                    { topMargin = False
                    , extra = [ Html.span [] [ Html.text "Versio 1.2.3" ] ]
                    }
                    { logo = Just Family.logo
                    , siteLabel = Just "Testipalvelu"
                    , links = Family.links
                    , groups = []
                    , copyright = Family.copyright 2026
                    , disclaimer = Just Family.disclaimer
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "footer"
                        , Selector.containing [ Selector.text "Versio 1.2.3" ]
                        , Selector.containing [ Selector.text "Testipalvelu" ]
                        , Selector.containing [ Selector.text "Palikkakalenteri" ]
                        , Selector.containing [ Selector.text "Suomen Palikkaharrastajat ry" ]
                        ]
        ]
