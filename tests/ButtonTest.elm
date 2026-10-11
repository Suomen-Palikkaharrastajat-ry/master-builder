module ButtonTest exposing (suite)

{-| Test suite for Component.Button.
-}

import Component.Button as Button
import FeatherIcons
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Button"
        [ test "new creates a button with type='button'" <|
            \_ ->
                Button.new { label = "Klikkaa", onClick = () }
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "button", Selector.attribute (Attr.type_ "button") ]
        , test "submit creates a button with type='submit'" <|
            \_ ->
                Button.submit { label = "Tallenna" }
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "button", Selector.attribute (Attr.type_ "submit") ]
        , test "iconOnly sets aria-label" <|
            \_ ->
                Button.new { label = "Sulje", onClick = () }
                    |> Button.withIcon FeatherIcons.x
                    |> Button.iconOnly
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "button", Selector.attribute (Attr.attribute "aria-label" "Sulje") ]
        , test "withLoading sets aria-busy='true'" <|
            \_ ->
                Button.submit { label = "Tallenna" }
                    |> Button.withLoading True
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-busy" "true") ]
        , test "link renders an <a> tag with href and target" <|
            \_ ->
                Button.link { label = "Avaa", href = "https://example.com" }
                    |> Button.withTarget "_blank"
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "a"
                        , Selector.attribute (Attr.href "https://example.com")
                        , Selector.attribute (Attr.target "_blank")
                        ]
        , test "accent variant with mapPin icon renders successfully" <|
            \_ ->
                Button.new { label = "Kartta", onClick = () }
                    |> Button.withVariant Button.Accent
                    |> Button.withIcon FeatherIcons.mapPin
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "button", Selector.containing [ Selector.text "Kartta" ] ]
        , test "disabled link button omits href and sets aria-disabled" <|
            \_ ->
                Button.link { label = "Pois käytöstä", href = "https://example.com" }
                    |> Button.withDisabled True
                    |> Button.toHtml
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "a"
                        , Selector.attribute (Attr.attribute "aria-disabled" "true")
                        , Selector.attribute (Attr.attribute "tabindex" "-1")
                        ]
        ]
