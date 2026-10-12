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
        , test "radioGroup with error renders alert and sets aria attributes on inputs" <|
            \_ ->
                Form.radioGroup
                    { legend = "Valitse tila"
                    , name = "status"
                    , required = True
                    , error = Just "Valinta on pakollinen"
                    }
                    { options =
                        [ { value = "draft", label = "Luonnos" }
                        , { value = "published", label = "Julkaistu" }
                        ]
                    , selected = "draft"
                    , onSelect = \_ -> ()
                    , layout = Form.Inline
                    }
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "input" ]
                    |> Query.each
                        (Query.has
                            [ Selector.attribute (Attr.attribute "aria-describedby" "status-error")
                            , Selector.attribute (Attr.attribute "aria-invalid" "true")
                            , Selector.attribute (Attr.attribute "aria-required" "true")
                            ]
                        )
        , test "fileInput renders file input with label and accept attribute" <|
            \_ ->
                Form.fileInput
                    (Form.defaultField "avatar" "Profiilikuva")
                    { accept = "image/png,image/jpeg"
                    , onFile = \_ -> ()
                    , preview = Nothing
                    }
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input" ]
                    |> Query.has
                        [ Selector.attribute (Attr.type_ "file")
                        , Selector.attribute (Attr.accept "image/png,image/jpeg")
                        , Selector.attribute (Attr.id "avatar")
                        ]
        , test "fileInput with error renders preview and error message" <|
            \_ ->
                let
                    field =
                        { id = "doc-upload"
                        , label = "Dokumentti"
                        , labelHidden = False
                        , hint = Nothing
                        , error = Just "Tiedosto on liian suuri"
                        , required = True
                        , disabled = False
                        }
                in
                Form.fileInput
                    field
                    { accept = "application/pdf"
                    , onFile = \_ -> ()
                    , preview = Just { src = "/preview.png", alt = "Preview" }
                    }
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "img"
                        , Selector.attribute (Attr.src "/preview.png")
                        , Selector.containing [ Selector.text "Tiedosto on liian suuri" ]
                        ]
        , test "fieldRow wraps fields in a flex row container" <|
            \_ ->
                Form.fieldRow
                    [ Html.text "Field A"
                    , Html.text "Field B"
                    ]
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.containing [ Selector.text "Field A" ]
                        , Selector.containing [ Selector.text "Field B" ]
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
