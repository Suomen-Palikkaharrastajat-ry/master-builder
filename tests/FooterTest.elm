module FooterTest exposing (suite)

{-| Test suite for Component.Footer and Component.Footer.Family.

The family footer is shared by every site, so these tests pin its content, order,
layout and typography. A failure here means every site's footer would change.

-}

import Component.Footer as Footer
import Component.Footer.Family as Family
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


canonicalFooter : Html msg
canonicalFooter =
    Family.view
        { currentSite = "https://kartta.palikkaharrastajat.fi"
        , year = 2026
        , topMargin = False
        , extra = []
        }


{-| Asserts that the footer's links are exactly `expected`, in order.
-}
expectLinks : List { label : String, href : String } -> Html msg -> Expect.Expectation
expectLinks expected html =
    let
        anchors =
            html
                |> Query.fromHtml
                |> Query.find [ Selector.tag "ul" ]
                |> Query.findAll [ Selector.tag "a" ]
    in
    Expect.all
        (Query.count (Expect.equal (List.length expected))
            :: List.indexedMap
                (\i link ->
                    Query.index i
                        >> Query.has
                            [ Selector.attribute (Attr.href link.href)
                            , Selector.text link.label
                            ]
                )
                expected
        )
        anchors


suite : Test
suite =
    describe "Component.Footer"
        [ describe "Family content"
            [ test "copyright formats year correctly" <|
                \_ ->
                    Family.copyright 2026
                        |> Expect.equal "© 2026 Suomen Palikkaharrastajat ry"
            , test "links is the canonical list, in canonical order" <|
                \_ ->
                    Family.links
                        |> Expect.equal
                            [ { label = "Kotisivut", href = "https://palikkaharrastajat.fi" }
                            , { label = "Palikkakalenteri", href = "https://kalenteri.palikkaharrastajat.fi" }
                            , { label = "Palikkakartta", href = "https://kartta.palikkaharrastajat.fi" }
                            , { label = "Palikkalinkit", href = "https://linkit.palikkaharrastajat.fi" }
                            , { label = "Jäsenfoorumi", href = "https://forum.palikkaharrastajat.fi" }
                            , { label = "Jäsenkortti", href = "https://kortti.palikkaharrastajat.fi" }
                            , { label = "Jäsenmaksu", href = "https://maksut.palikkaharrastajat.fi" }
                            , { label = "Tietosuoja", href = "https://palikkaharrastajat.fi/tietosuoja" }
                            ]
            , test "links has no duplicate targets or labels" <|
                \_ ->
                    let
                        unique items =
                            List.foldl
                                (\item acc ->
                                    if List.member item acc then
                                        acc

                                    else
                                        item :: acc
                                )
                                []
                                items
                    in
                    ( List.length (unique (List.map .href Family.links))
                    , List.length (unique (List.map .label Family.links))
                    )
                        |> Expect.equal ( List.length Family.links, List.length Family.links )
            , test "linksExcept drops only the current site" <|
                \_ ->
                    Family.linksExcept "https://palikkaharrastajat.fi"
                        |> List.map .label
                        |> Expect.equal
                            [ "Palikkakalenteri"
                            , "Palikkakartta"
                            , "Palikkalinkit"
                            , "Jäsenfoorumi"
                            , "Jäsenkortti"
                            , "Jäsenmaksu"
                            , "Tietosuoja"
                            ]
            ]
        , describe "Family.view"
            [ test "renders the canonical links without the current site" <|
                \_ ->
                    canonicalFooter
                        |> expectLinks (Family.linksExcept "https://kartta.palikkaharrastajat.fi")
            , test "renders label, copyright, disclaimer and logo" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "footer"
                            , Selector.containing [ Selector.text Family.siteLabel ]
                            , Selector.containing [ Selector.text "© 2026 Suomen Palikkaharrastajat ry" ]
                            , Selector.containing [ Selector.text "LEGO® on LEGO Groupin rekisteröity tavaramerkki." ]
                            , Selector.containing [ Selector.tag "img", Selector.class "h-35", Selector.class "w-35" ]
                            ]
            , test "label is 12px uppercase" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "p", Selector.class "uppercase" ]
                        |> Query.has
                            [ Selector.classes [ "text-xs", "font-semibold", "tracking-wider" ]
                            , Selector.text Family.siteLabel
                            ]
            , test "links are 14px in two columns from sm up, one below" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "ul" ]
                        |> Expect.all
                            [ Query.has [ Selector.classes [ "grid", "sm:grid-cols-2", "gap-x-6", "gap-y-2", "list-none" ] ]

                            -- space-y-* on a grid offsets every row but the first
                            , Query.hasNot [ Selector.class "space-y-2" ]
                            , Query.hasNot [ Selector.class "grid-cols-2" ]
                            , Query.findAll [ Selector.tag "a" ]
                                >> Query.each (Query.has [ Selector.classes [ "text-sm", "underline" ] ])
                            ]
            , test "legal text is 12px" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.containing
                                [ Selector.classes [ "space-y-1", "text-xs" ]
                                , Selector.containing [ Selector.text "© 2026 Suomen Palikkaharrastajat ry" ]
                                ]
                            ]
            , test "topMargin switches between mt-auto and mt-16" <|
                \_ ->
                    Expect.all
                        [ \_ ->
                            canonicalFooter
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "mt-auto" ]
                        , \_ ->
                            Family.view { currentSite = "", year = 2026, topMargin = True, extra = [] }
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "mt-16" ]
                        ]
                        ()
            ]
        , describe "Family.viewWith"
            [ test "renders the supplied content with the family logo and layout" <|
                \_ ->
                    Family.viewWith
                        { topMargin = False
                        , extra = [ Html.span [] [ Html.text "Versio 1.2.3" ] ]
                        , siteLabel = "Testipalvelu"
                        , links = [ { label = "Homepage", href = "https://palikkaharrastajat.fi" } ]
                        , copyright = "Content is owned by its creators."
                        , disclaimer = [ "Disclaimer line" ]
                        }
                        |> Expect.all
                            [ expectLinks [ { label = "Homepage", href = "https://palikkaharrastajat.fi" } ]
                            , Query.fromHtml
                                >> Query.has
                                    [ Selector.tag "footer"
                                    , Selector.containing [ Selector.text "Versio 1.2.3" ]
                                    , Selector.containing [ Selector.text "Testipalvelu" ]
                                    , Selector.containing [ Selector.text "Content is owned by its creators." ]
                                    , Selector.containing [ Selector.text "Disclaimer line" ]
                                    , Selector.containing [ Selector.tag "img", Selector.class "h-35" ]
                                    ]
                            ]
            ]
        , describe "Footer.viewWith"
            [ test "renders footer with extra content and copyright" <|
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
                            ]
            ]
        ]
