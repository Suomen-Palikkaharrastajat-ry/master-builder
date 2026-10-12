module LayoutTest exposing (suite)

{-| Test suite for Component.Layout, the page shell shared by every site.

The shell is fed the resolver's real output (SiteSettingsFixture), so these
tests cover the whole path from `config.toml` to rendered chrome.

-}

import Component.Layout as Layout
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Decode
import Lang exposing (Lang(..))
import SiteSettings exposing (SiteSettings)
import SiteSettingsFixture
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import UiStrings


site : Lang -> Maybe SiteSettings
site lang =
    Decode.decodeString SiteSettings.localizedDecoder SiteSettingsFixture.json
        |> Result.toMaybe
        |> Maybe.andThen (SiteSettings.forLang lang)


type Msg
    = Toggle
    | Close


shell : (Layout.Config Msg -> Layout.Config Msg) -> Lang -> Html Msg
shell change lang =
    case site lang of
        Just settings ->
            Html.div []
                (Layout.view
                    (change
                        { site = settings
                        , strings = UiStrings.forLang lang
                        , attributes = []
                        , home = { href = "/", onClick = Nothing }
                        , links = [ { label = "Tapahtumat", href = "#/events", mobileOnly = False, isActive = True } ]
                        , headerActions = []
                        , showHeader = True
                        , menu =
                            Just
                                { isOpen = False
                                , onToggle = Toggle
                                , onClose = Close
                                , content = \links -> [ links ]
                                }
                        , main = Html.main_ [ Attr.id "main-content" ] [ Html.text "Sisältö" ]
                        , aboveFooter = []
                        , footer = Just { topMargin = False, extra = [] }
                        , scrollToTop = Nothing
                        , toasts = Just []
                        , overlays = []
                        }
                    )
                )

        Nothing ->
            Html.text "fixture did not decode"


has : List Selector.Selector -> Html Msg -> Expect.Expectation
has selectors html =
    html |> Query.fromHtml |> Query.has selectors


suite : Test
suite =
    describe "Component.Layout"
        [ test "skip link targets the main area, labelled in the current language" <|
            \_ ->
                Expect.all
                    [ \_ -> shell identity Fi |> has [ Selector.containing [ Selector.tag "a", Selector.attribute (Attr.href "#main-content"), Selector.text "Siirry pääsisältöön" ] ]
                    , \_ -> shell identity En |> has [ Selector.containing [ Selector.tag "a", Selector.attribute (Attr.href "#main-content"), Selector.text "Skip to main content" ] ]
                    ]
                    ()
        , test "brand shows the configured title and square logo" <|
            \_ ->
                Expect.all
                    [ \_ -> shell identity Fi |> has [ Selector.containing [ Selector.tag "header", Selector.containing [ Selector.text "Palikkakalenteri" ] ] ]
                    , \_ -> shell identity En |> has [ Selector.containing [ Selector.tag "header", Selector.containing [ Selector.text "Brick Calendar" ] ] ]
                    , \_ -> shell identity Fi |> has [ Selector.containing [ Selector.tag "img", Selector.attribute (Attr.src "/logo/square/svg/square-smile.svg") ] ]
                    ]
                    ()
        , test "menu button and drawer are named from the layout strings" <|
            \_ ->
                Expect.all
                    [ \_ -> shell identity Fi |> has [ Selector.containing [ Selector.tag "button", Selector.attribute (Attr.attribute "aria-label" "Avaa valikko"), Selector.attribute (Attr.attribute "aria-controls" "mobile-nav") ] ]
                    , \_ -> shell identity En |> has [ Selector.containing [ Selector.id "mobile-nav", Selector.attribute (Attr.attribute "aria-label" "Mobile menu") ] ]
                    , \_ -> shell identity En |> has [ Selector.containing [ Selector.id "mobile-nav", Selector.containing [ Selector.text "Close menu" ] ] ]
                    ]
                    ()
        , test "navigation links appear in the header and in the drawer" <|
            \_ ->
                shell identity Fi
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "a", Selector.attribute (Attr.href "#/events") ]
                    |> Query.count (Expect.equal 2)
        , test "footer comes from the resolved configuration" <|
            \_ ->
                Expect.all
                    [ \_ -> shell identity Fi |> has [ Selector.containing [ Selector.tag "footer", Selector.containing [ Selector.text "LEGO® on LEGO Groupin rekisteröity tavaramerkki." ] ] ]
                    , \_ -> shell identity En |> has [ Selector.containing [ Selector.tag "footer", Selector.containing [ Selector.text "Homepage" ] ] ]
                    , \_ -> shell (\c -> { c | footer = Nothing }) Fi |> Query.fromHtml |> Query.hasNot [ Selector.tag "footer" ]
                    ]
                    ()
        , test "a header without a menu has no menu button and no drawer" <|
            \_ ->
                shell (\c -> { c | menu = Nothing }) Fi
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "header" ]
                        , Query.hasNot [ Selector.id "mobile-nav" ]
                        , Query.hasNot [ Selector.attribute (Attr.attribute "aria-controls" "mobile-nav") ]
                        ]
        , test "the menu button can be found to return focus to it" <|
            \_ ->
                shell identity Fi
                    |> has [ Selector.containing [ Selector.id Layout.menuButtonId, Selector.containing [ Selector.tag "button" ] ] ]
        , test "an embedded view has no header and no drawer" <|
            \_ ->
                shell (\c -> { c | showHeader = False, menu = Nothing }) Fi
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.hasNot [ Selector.tag "header" ]
                        , Query.hasNot [ Selector.id "mobile-nav" ]
                        , Query.has [ Selector.containing [ Selector.id "main-content" ] ]
                        ]
        , test "the standard variant renders the horizontal logo with its alt text" <|
            \_ ->
                shell (\c -> { c | site = withVariant "standard" c.site }) Fi
                    |> has [ Selector.containing [ Selector.tag "img", Selector.attribute (Attr.alt "Suomen Palikkaharrastajat ry") ] ]
        , test "toast region is labelled in the current language" <|
            \_ ->
                shell identity En
                    |> has [ Selector.containing [ Selector.attribute (Attr.attribute "role" "region"), Selector.attribute (Attr.attribute "aria-label" "Notifications") ] ]
        ]


withVariant : String -> SiteSettings -> SiteSettings
withVariant variant settings =
    let
        navbar =
            settings.navbar
    in
    { settings | navbar = { navbar | variant = variant } }
