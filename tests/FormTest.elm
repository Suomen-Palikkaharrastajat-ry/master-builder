module FormTest exposing (suite)

{-| Test suite for Component.Form.
-}

import Component.Form as Form
import Expect
import Html
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Form"
        [ test "textInput associates label for with input id" <|
            \_ ->
                Form.textInput
                    (Form.defaultField "test-input" "Test Label")
                    { value = "hello"
                    , onInput = \_ -> ()
                    , inputType = Form.Text
                    , placeholder = Just "Type here"
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "label"
                        , Selector.attribute (Attr.for "test-input")
                        , Selector.containing [ Selector.text "Test Label" ]
                        ]
        , test "textInput includes aria-describedby for hint and error" <|
            \_ ->
                let
                    field =
                        { id = "email-field"
                        , label = "Email address"
                        , labelHidden = False
                        , hint = Just "Enter your work email"
                        , error = Just "Invalid email format"
                        , required = True
                        , disabled = False
                        }
                in
                Form.textInput field
                    { value = "bad@"
                    , onInput = \_ -> ()
                    , inputType = Form.Email
                    , placeholder = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input" ]
                    |> Query.has
                        [ Selector.attribute (Attr.attribute "aria-describedby" "email-field-hint email-field-error")
                        , Selector.attribute (Attr.attribute "aria-invalid" "true")
                        , Selector.attribute (Attr.attribute "aria-required" "true")
                        ]
        , test "textInput with labelHidden renders label with sr-only" <|
            \_ ->
                let
                    field =
                        { id = "search-field"
                        , label = "Haku"
                        , labelHidden = True
                        , hint = Nothing
                        , error = Nothing
                        , required = False
                        , disabled = False
                        }
                in
                Form.textInput field
                    { value = ""
                    , onInput = \_ -> ()
                    , inputType = Form.Search
                    , placeholder = Just "Etsi..."
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "label" ]
                    |> Query.has
                        [ Selector.class "sr-only"
                        , Selector.containing [ Selector.text "Haku" ]
                        ]
        , test "radioGroup renders fieldset and legend" <|
            \_ ->
                Form.radioGroup
                    { legend = "Valitse tila"
                    , name = "status"
                    , required = True
                    , error = Nothing
                    }
                    { options =
                        [ { value = "draft", label = "Luonnos" }
                        , { value = "published", label = "Julkaistu" }
                        ]
                    , selected = "draft"
                    , onSelect = \_ -> ()
                    , layout = Form.Chips
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "fieldset"
                        , Selector.tag "legend"
                        , Selector.containing [ Selector.text "Valitse tila" ]
                        ]
        , test "checkbox renders accessible input and label" <|
            \_ ->
                Form.checkbox
                    (Form.defaultField "agree-terms" "Hyväksyn ehdot")
                    { checked = True
                    , onCheck = \_ -> ()
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "label"
                        , Selector.attribute (Attr.for "agree-terms")
                        , Selector.containing [ Selector.text "Hyväksyn ehdot" ]
                        ]
        , test "textarea associates label for with id" <|
            \_ ->
                Form.textarea
                    (Form.defaultField "comments" "Kommentit")
                    { value = "Huomautus"
                    , onInput = \_ -> ()
                    , rows = 4
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "label"
                        , Selector.attribute (Attr.for "comments")
                        , Selector.containing [ Selector.text "Kommentit" ]
                        ]
        ]
