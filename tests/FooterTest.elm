module FooterTest exposing (suite)

{-| Test suite for Component.Footer and Component.Footer.Family.

The family footer is shared by every site, so these tests pin its layout and
typography. Its content comes from configuration; the canonical link list is
pinned in packages/site-config/site-config.test.mjs. A failure here means every site's footer would change.

-}

import Component.Footer as Footer
import Component.Footer.Family as Family
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import SiteSettings
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


footer : SiteSettings.Footer
footer =
    { links =
        [ { label = "Kotisivut", href = "https://palikkaharrastajat.fi" }
        , { label = "Palikkakalenteri", href = "https://kalenteri.palikkaharrastajat.fi" }
        , { label = "Tietosuoja", href = "https://palikkaharrastajat.fi/tietosuoja" }
        ]
    , copyright = "© 2026 Suomen Palikkaharrastajat ry"
    , disclaimer = [ "LEGO® on LEGO Groupin rekisteröity tavaramerkki." ]
    , footerLogo = "/logo/square/svg/square-smile-full-dark-bold.svg"
    , siteLabel = "Palikkaharrastajat"
    }


canonicalFooter : Html msg
canonicalFooter =
    Family.view { topMargin = False, extra = [] } footer


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
        [ describe "Family.view"
            [ test "renders the configured links, in order" <|
                \_ ->
                    canonicalFooter
                        |> expectLinks footer.links
            , test "renders label, copyright, disclaimer and logo" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "footer"
                            , Selector.containing [ Selector.text footer.siteLabel ]
                            , Selector.containing [ Selector.text "© 2026 Suomen Palikkaharrastajat ry" ]
                            , Selector.containing [ Selector.text "LEGO® on LEGO Groupin rekisteröity tavaramerkki." ]
                            , Selector.containing [ Selector.tag "img", Selector.class "h-35", Selector.class "w-35", Selector.attribute (Attr.src footer.footerLogo) ]
                            ]
            , test "label is 12px uppercase" <|
                \_ ->
                    canonicalFooter
                        |> Query.fromHtml
                        |> Query.find [ Selector.tag "p", Selector.class "uppercase" ]
                        |> Query.has
                            [ Selector.classes [ "text-xs", "font-semibold", "tracking-wider" ]
                            , Selector.text footer.siteLabel
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
                            Family.view { topMargin = True, extra = [] } footer
                                |> Query.fromHtml
                                |> Query.has [ Selector.class "mt-16" ]
                        ]
                        ()
            , test "extra lines are shown under the disclaimer" <|
                \_ ->
                    Family.view { topMargin = False, extra = [ Html.span [] [ Html.text "Versio 1.2.3" ] ] } footer
                        |> Query.fromHtml
                        |> Query.has [ Selector.containing [ Selector.text "Versio 1.2.3" ] ]
            ]
        , describe "Footer.viewWith"
            [ test "renders footer with extra content and copyright" <|
                \_ ->
                    Footer.viewWith
                        { topMargin = False
                        , extra = [ Html.span [] [ Html.text "Versio 1.2.3" ] ]
                        }
                        { logo = Just (Html.img [ Attr.src footer.footerLogo ] [])
                        , siteLabel = Just "Testipalvelu"
                        , links = footer.links
                        , groups = []
                        , copyright = footer.copyright
                        , disclaimer = Just footer.disclaimer
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
