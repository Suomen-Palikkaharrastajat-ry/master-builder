module Admin.ComponentCatalog exposing (AttributeField, ComponentSpec, all, find, initialValues, snippet)

{-| Component snippets available in the admin Markdown builder.
-}

import Dict exposing (Dict)


type alias ComponentSpec =
    { tag : String
    , label : String
    , description : String
    , attributes : List AttributeField
    , body : Maybe String
    }


type alias AttributeField =
    { name : String
    , label : String
    , default : String
    }


all : List ComponentSpec
all =
    [ body "callout" "Callout" "Alert box for info, success, warning, or error notes." [ attr "type" "Type" "info", attr "icon" "Icon" "" ] "Important note goes here."
    , body "hero" "Hero" "Large heading block with optional call-to-action children." [ attr "title" "Title" "Page title", attr "subtitle" "Subtitle" "Short supporting text" ] "[Read more](https://example.com)"
    , body "feature-grid" "Feature grid" "Responsive feature card grid." [ attr "columns" "Columns" "2" ] "<feature title=\"Feature\" icon=\"star\">\nFeature body.\n</feature>"
    , body "feature" "Feature" "Single feature item, usually inside a feature grid." [ attr "title" "Title" "Feature", attr "icon" "Icon" "star", attr "href" "Link" "" ] "Feature body."
    , body "pricing-table" "Pricing table" "Pricing tier wrapper." [ attr "highlighted" "Highlighted tier" "" ] "<pricing-tier name=\"Jäsenmaksu\" price=\"10 €\" period=\"vuosi\">\nTier details.\n</pricing-tier>"
    , body "pricing-tier" "Pricing tier" "Single pricing tier." [ attr "name" "Name" "Jäsenmaksu", attr "price" "Price" "10 €", attr "period" "Period" "vuosi", attr "href" "Link" "" ] "Tier details."
    , empty "button-link" "Button link" "Button-styled link." [ attr "href" "Link" "https://example.com", attr "variant" "Variant" "primary", attr "label" "Label" "Lue lisää" ]
    , body "card" "Card" "Bordered content card." [ attr "title" "Title" "Card title" ] "Card body."
    , empty "badge" "Badge" "Small label badge." [ attr "color" "Color" "yellow", attr "label" "Label" "Badge" ]
    , body "accordion" "Accordion" "Accordion wrapper." [] "<accordion-item summary=\"Question\">\nAnswer.\n</accordion-item>"
    , body "accordion-item" "Accordion item" "Single accordion item." [ attr "summary" "Summary" "Question" ] "Answer."
    , body "stat-grid" "Stat grid" "Statistics wrapper." [] "<stat label=\"Members\" value=\"100+\" change=\"+10\" />"
    , empty "stat" "Stat" "Single stat item." [ attr "label" "Label" "Members", attr "value" "Value" "100+", attr "change" "Change" "" ]
    , body "timeline" "Timeline" "Timeline wrapper." [] "<timeline-item date=\"2026\" title=\"Milestone\">\nDetails.\n</timeline-item>"
    , body "timeline-item" "Timeline item" "Single timeline event." [ attr "date" "Date" "2026", attr "title" "Title" "Milestone", attr "icon" "Icon" "calendar", attr "image" "Image" "" ] "Details."
    , body "gallery" "Gallery" "Gallery wrapper." [ attr "title" "Title" "Gallery", attr "description" "Description" "", attr "columns" "Columns" "3" ] "<gallery-item id=\"item\" description=\"Description\" svg=\"/logo/square/svg/square-basic.svg\" />"
    , empty "gallery-item" "Gallery item" "Single gallery logo/image item." [ attr "id" "Id" "item", attr "description" "Description" "Description", attr "theme" "Theme" "light", attr "animated" "Animated" "", attr "with-text" "With text" "", attr "bold" "Bold" "", attr "highlight" "Highlight" "", attr "svg" "SVG" "", attr "png" "PNG" "", attr "webp" "WebP" "", attr "gif" "GIF" "" ]
    , body "color-grid" "Color grid" "Color swatch wrapper." [ attr "title" "Title" "Colors", attr "description" "Description" "", attr "columns" "Columns" "3" ] "<color-grid-item name=\"Brand\" hex=\"#05131D\" description=\"Primary\" usage=\"brand\" />"
    , empty "color-grid-item" "Color item" "Single color swatch." [ attr "name" "Name" "Brand", attr "hex" "Hex" "#05131D", attr "description" "Description" "Primary", attr "usage" "Usage tags" "brand" ]
    , body "info-panel" "Info panel" "Colored information panel." [ attr "color" "Color" "amber", attr "title" "Title" "Note", attr "icon" "Icon" "info" ] "Panel body."
    , body "with-image" "With image" "Two-column image/content block." [ attr "src" "Image source" "/images/example.png", attr "alt" "Alt text" "", attr "side" "Side" "right", attr "caption" "Caption" "", attr "maxwidth" "Max width" "" ] "Text content."
    , empty "spinner" "Spinner" "Loading spinner." [ attr "size" "Size" "medium", attr "label" "Label" "Ladataan" ]
    , empty "progress-bar" "Progress bar" "Progress indicator." [ attr "value" "Value" "75", attr "max" "Max" "100", attr "label" "Label" "Progress", attr "color" "Color" "brand" ]
    , empty "section-header" "Section header" "Section heading." [ attr "title" "Title" "Heading", attr "description" "Description" "" ]
    , empty "section-subheader" "Section subheader" "Subsection heading." [ attr "title" "Title" "Subheading", attr "description" "Description" "" ]
    , empty "toast" "Toast" "Toast notification example." [ attr "variant" "Variant" "default", attr "title" "Title" "Notice", attr "body" "Body" "Toast body." ]
    , empty "tag" "Tag" "Removable-style tag." [ attr "label" "Label" "Tag" ]
    , body "tab-group" "Tab group" "Preview/example tabs." [ attr "name" "Name" "example-tabs" ] "<preview>\nPreview content.\n</preview>\n\n<example>\n```elm\nexample\n```\n</example>"
    , body "preview" "Preview tab" "Preview panel inside a tab group." [] "Preview content."
    , body "example" "Example tab" "Example/code panel inside a tab group." [] "Example content."
    ]


find : String -> Maybe ComponentSpec
find tag =
    all
        |> List.filter (\spec -> spec.tag == tag)
        |> List.head


initialValues : ComponentSpec -> Dict String String
initialValues spec =
    spec.attributes
        |> List.map (\field -> ( field.name, field.default ))
        |> Dict.fromList


snippet : ComponentSpec -> Dict String String -> String -> String
snippet spec values bodyText =
    let
        attrs =
            spec.attributes
                |> List.filterMap
                    (\field ->
                        Dict.get field.name values
                            |> Maybe.withDefault field.default
                            |> String.trim
                            |> (\value ->
                                    if String.isEmpty value then
                                        Nothing

                                    else
                                        Just (field.name ++ "=\"" ++ escapeAttribute value ++ "\"")
                               )
                    )
                |> String.join " "

        openTag =
            if String.isEmpty attrs then
                "<" ++ spec.tag ++ ">"

            else
                "<" ++ spec.tag ++ " " ++ attrs ++ ">"
    in
    case spec.body of
        Nothing ->
            if String.isEmpty attrs then
                "<" ++ spec.tag ++ " />"

            else
                "<" ++ spec.tag ++ " " ++ attrs ++ " />"

        Just _ ->
            openTag ++ "\n\n" ++ bodyText ++ "\n\n</" ++ spec.tag ++ ">"


attr : String -> String -> String -> AttributeField
attr name label default =
    { name = name, label = label, default = default }


body : String -> String -> String -> List AttributeField -> String -> ComponentSpec
body tag label description attributes bodyText =
    { tag = tag, label = label, description = description, attributes = attributes, body = Just bodyText }


empty : String -> String -> String -> List AttributeField -> ComponentSpec
empty tag label description attributes =
    { tag = tag, label = label, description = description, attributes = attributes, body = Nothing }


escapeAttribute : String -> String
escapeAttribute value =
    value
        |> String.replace "&" "&amp;"
        |> String.replace "\"" "&quot;"
