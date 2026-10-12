module MapOverlayTest exposing (suite)

{-| Test suite for View.MapOverlay module.
-}

import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import View.MapOverlay as MapOverlay


suite : Test
suite =
    describe "View.MapOverlay"
        [ describe "panel"
            [ test "renders div when label is Nothing" <|
                \_ ->
                    MapOverlay.panel
                        { position = MapOverlay.BottomLeft
                        , label = Nothing
                        }
                        [ Html.text "Content" ]
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "div", Selector.containing [ Selector.text "Content" ] ]
            , test "renders section with aria-label when label is Just" <|
                \_ ->
                    MapOverlay.panel
                        { position = MapOverlay.TopLeft
                        , label = Just "Map Controls"
                        }
                        [ Html.text "Controls" ]
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "section"
                            , Selector.attribute (Attr.attribute "aria-label" "Map Controls")
                            , Selector.containing [ Selector.text "Controls" ]
                            ]
            ]
        , describe "filterGroup"
            [ test "renders fieldset and sr-only legend" <|
                \_ ->
                    MapOverlay.filterGroup
                        { legend = "Tag filters" }
                        [ Html.text "Checkbox 1" ]
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "fieldset"
                            , Selector.tag "legend"
                            , Selector.containing [ Selector.text "Tag filters" ]
                            ]
            ]
        , describe "detailPanel"
            [ test "renders nothing when isOpen is False" <|
                \_ ->
                    MapOverlay.detailPanel
                        { isOpen = False
                        , onClose = ()
                        , closeLabel = "Sulje"
                        , title = "Kohde"
                        }
                        [ Html.text "Details" ]
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.tag "aside" ]
            , test "renders accessible aside with title and close button when isOpen is True" <|
                \_ ->
                    MapOverlay.detailPanel
                        { isOpen = True
                        , onClose = ()
                        , closeLabel = "Sulje paneeli"
                        , title = "Lelumuseo"
                        }
                        [ Html.text "Museon kuvaus" ]
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.tag "aside"
                            , Selector.id "map-detail-panel"
                            , Selector.attribute (Attr.attribute "role" "region")
                            , Selector.attribute (Attr.attribute "aria-label" "Lelumuseo")
                            , Selector.containing [ Selector.text "Lelumuseo" ]
                            , Selector.containing [ Selector.text "Museon kuvaus" ]
                            ]
            , test "renders close button with id and aria-label" <|
                \_ ->
                    MapOverlay.detailPanel
                        { isOpen = True
                        , onClose = ()
                        , closeLabel = "Sulje paneeli"
                        , title = "Lelumuseo"
                        }
                        [ Html.text "Museon kuvaus" ]
                        |> Query.fromHtml
                        |> Query.find [ Selector.id "map-detail-close" ]
                        |> Query.has
                            [ Selector.tag "button"
                            , Selector.attribute (Attr.attribute "aria-label" "Sulje paneeli")
                            ]
            , test "renders extra header actions when using detailPanelWithHeaderActions" <|
                \_ ->
                    MapOverlay.detailPanelWithHeaderActions
                        { isOpen = True
                        , onClose = ()
                        , closeLabel = "Sulje"
                        , title = "Kohde"
                        , headerActions = [ Html.a [ Attr.id "edit-btn" ] [ Html.text "Muokkaa" ] ]
                        }
                        [ Html.text "Sisältö" ]
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.id "edit-btn"
                            , Selector.containing [ Selector.text "Muokkaa" ]
                            ]
            ]
        , describe "positions"
            [ test "TopCenter includes translate class" <|
                \_ ->
                    MapOverlay.panel
                        { position = MapOverlay.TopCenter
                        , label = Nothing
                        }
                        []
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "-translate-x-1/2" ]
            , test "TopRight includes right-4 class" <|
                \_ ->
                    MapOverlay.panel
                        { position = MapOverlay.TopRight
                        , label = Nothing
                        }
                        []
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "right-4" ]
            , test "BottomRight includes right-4 and bottom-8" <|
                \_ ->
                    MapOverlay.panel
                        { position = MapOverlay.BottomRight
                        , label = Nothing
                        }
                        []
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "right-4", Selector.class "bottom-8" ]
            ]
        ]
