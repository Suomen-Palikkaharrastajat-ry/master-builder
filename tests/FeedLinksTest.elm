module FeedLinksTest exposing (suite)

{-| Test suite for Component.FeedLinks.
-}

import Component.FeedLinks as FeedLinks
import FeatherIcons
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.FeedLinks"
        [ test "renders section with aria-label" <|
            \_ ->
                FeedLinks.view
                    { label = "Tilaukset ja viennit"
                    , cards =
                        [ { icon = FeatherIcons.calendar
                          , title = "iCalendar"
                          , description = "Tilaa kalenteriisi"
                          , href = "/events.ics"
                          }
                        ]
                    , feeds =
                        Just
                            { icon = FeatherIcons.rss
                            , title = "Syötteet"
                            , description = "Tapahtumat syötteenä"
                            , links =
                                [ { label = "Atom", href = "/feed.atom" }
                                , { label = "RSS", href = "/feed.rss" }
                                ]
                            }
                    , newTabHint = "(avautuu uuteen välilehteen)"
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "section"
                        , Selector.attribute (Attr.attribute "aria-label" "Tilaukset ja viennit")
                        , Selector.containing [ Selector.text "iCalendar" ]
                        , Selector.containing [ Selector.text "Tilaa kalenteriisi" ]
                        , Selector.containing [ Selector.text "Atom" ]
                        , Selector.containing [ Selector.text "RSS" ]
                        , Selector.containing [ Selector.text "(avautuu uuteen välilehteen)" ]
                        ]
        ]
