module NavbarTest exposing (suite)

{-| Test suite for Component.Navbar.
-}

import Component.Navbar as Navbar
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Navbar"
        [ test "viewBrand renders link with href and logo + title" <|
            \_ ->
                Navbar.viewBrand
                    { href = "/"
                    , onClick = Nothing
                    , iconSrc = "/logo.svg"
                    , title = "Palikkaharrastajat"
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "a"
                        , Selector.attribute (Attr.href "/")
                        , Selector.containing [ Selector.text "Palikkaharrastajat" ]
                        ]
        , test "viewMenuToggle renders button with aria-expanded and aria-controls" <|
            \_ ->
                Navbar.viewMenuToggle
                    { isOpen = True
                    , onToggle = ()
                    , controls = "mobile-menu"
                    , openLabel = "Avaa valikko"
                    , closeLabel = "Sulje valikko"
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "button"
                        , Selector.attribute (Attr.attribute "aria-expanded" "true")
                        , Selector.attribute (Attr.attribute "aria-controls" "mobile-menu")
                        , Selector.attribute (Attr.attribute "aria-label" "Sulje valikko")
                        ]
        , test "viewAppHeader renders header with nav and brand" <|
            \_ ->
                Navbar.viewAppHeader
                    { brand = Html.span [] [ Html.text "Logo" ]
                    , navLabel = "Päävalikko"
                    , links =
                        [ { label = "Etusivu", href = "/", mobileOnly = False, isActive = True }
                        , { label = "Tietoja", href = "/about", mobileOnly = True, isActive = False }
                        ]
                    , trailing = [ Html.span [] [ Html.text "Oikea" ] ]
                    , menuToggle = Nothing
                    , sticky = True
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "header"
                        , Selector.tag "nav"
                        , Selector.attribute (Attr.attribute "aria-label" "Päävalikko")
                        , Selector.containing [ Selector.text "Etusivu" ]
                        ]
        ]
