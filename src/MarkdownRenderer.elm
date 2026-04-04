module MarkdownRenderer exposing (renderMarkdown)

{-| Markdown renderer for elm-pages content.
-}

import Component.Accordion as Accordion
import Component.Alert as Alert
import Component.Card as Card
import Component.ColorSwatch as ColorSwatch
import Component.Gallery as Gallery
import Component.Hero as Hero
import Component.LogoCard as LogoCard
import Component.Progress as Progress
import Component.SectionHeader as SectionHeader
import Component.Spinner as Spinner
import Component.Stats as Stats
import Component.Tag as Tag
import Component.Timeline as Timeline
import Component.Toast as Toast
import DesignTokens.Guide.Colors as Colors
import DesignTokens.Guide.Logos as Logos
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Regex
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th exposing (s0_dot_5, s1, s10, s1_dot_5, s2, s2_dot_5, s3, s4, s6, s8, white)
import TailwindExtra as TwEx
import TailwindTokens as TC


splitClassPrefix : String -> ( Maybe String, String )
splitClassPrefix str =
    case Regex.fromString "^\\{([^}]*)\\}\\s*(.*)$" of
        Nothing ->
            ( Nothing, str )

        Just re ->
            case Regex.find re str of
                [] ->
                    ( Nothing, str )

                match :: _ ->
                    case match.submatches of
                        [ maybeCls, maybeRest ] ->
                            let
                                cls =
                                    maybeCls

                                rest =
                                    case maybeRest of
                                        Just r ->
                                            r

                                        Nothing ->
                                            ""
                            in
                            ( cls, rest )

                        _ ->
                            ( Nothing, str )


renderMarkdown : String -> Html msg
renderMarkdown markdown =
    case
        markdown
            |> Markdown.Parser.parse
            |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
            |> Result.andThen (Markdown.Renderer.render renderer)
    of
        Ok rendered ->
            Html.article [ classes [ Tw.prose, Tw.prose_gray, Tw.max_w_none ] ] rendered

        Err err ->
            Html.pre [ classes [ Tw.text_simple TC.brandRed, Tw.type_caption, Tw.p s4, TwEx.bg_brand_red_10, Tw.rounded ] ] [ Html.text err ]


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    { heading = viewHeading
    , paragraph = Html.p [ classes [ Tw.my s4, TwEx.leading_7, Tw.text_simple TC.textPrimary ] ]
    , hardLineBreak = Html.br [] []
    , blockQuote =
        \children ->
            Html.blockquote
                [ classes [ Tw.pl s4, Tw.border_l_4, Tw.border_simple TC.borderDefault, Tw.text_simple TC.textMuted, Tw.italic, Tw.my s6 ] ]
                children
    , strong = \children -> Html.strong [ classes [ Tw.type_body_small, Tw.text_simple TC.textPrimary ] ] children
    , emphasis = \children -> Html.em [ classes [ Tw.italic ] ] children
    , strikethrough = \children -> Html.s [] children
    , codeSpan =
        \code ->
            Html.code
                [ classes [ Tw.px s1_dot_5, Tw.py s0_dot_5, Tw.rounded, Tw.bg_simple TC.bgSubtle, Tw.text_simple TC.textPrimary, Tw.type_mono ] ]
                [ Html.text code ]
    , link = viewLink
    , image = viewImage
    , text = Html.text
    , unorderedList = viewUnorderedList
    , orderedList = viewOrderedList
    , codeBlock = viewCodeBlock
    , thematicBreak = Html.hr [ classes [ Tw.my s8, Tw.border_simple TC.borderDefault ] ] []
    , table = Html.table [ classes [ Tw.w_full, Tw.type_caption, Tw.border_collapse, Tw.my s6, Tw.rounded, Tw.overflow_hidden ] ]
    , tableHeader = Html.thead [ classes [ Tw.bg_simple TC.bgSubtle, Tw.border_b, Tw.border_simple TC.borderDefault ] ]
    , tableBody = Html.tbody []
    , tableRow = Html.tr [ classes [ Tw.border_b, Tw.border_simple TC.borderDefault, Bp.last [ Tw.border_0 ] ] ]
    , tableHeaderCell =
        \_ children ->
            Html.th [ classes [ Tw.px s4, Tw.py s2, Tw.text_left, Tw.type_body_small, Tw.text_simple TC.textMuted ] ] children
    , tableCell =
        \_ children ->
            Html.td [ classes [ Tw.px s4, Tw.py s2, Tw.text_simple TC.textPrimary ] ] children
    , html = htmlRenderer
    }


viewHeading :
    { level : Block.HeadingLevel, rawText : String, children : List (Html msg) }
    -> Html msg
viewHeading { level, children } =
    case level of
        Block.H1 ->
            Html.h1 [ classes [ Tw.type_h1, Tw.tracking_tight, Tw.text_simple TC.textPrimary, Tw.mt s8, Tw.mb s4 ] ] children

        Block.H2 ->
            Html.h2 [ classes [ Tw.type_h2, Tw.text_simple TC.textPrimary, Tw.mt s8, Tw.mb s3, Tw.border_b, Tw.border_simple TC.borderDefault, Tw.pb s2 ] ] children

        Block.H3 ->
            Html.h3 [ classes [ Tw.type_h3, Tw.text_simple TC.textPrimary, Tw.mt s6, Tw.mb s2 ] ] children

        Block.H4 ->
            Html.h4 [ classes [ Tw.type_h4, Tw.text_simple TC.textPrimary, Tw.mt s4, Tw.mb s1 ] ] children

        Block.H5 ->
            Html.h5 [ classes [ Tw.type_overline, Tw.text_simple TC.textMuted, Tw.mt s3, Tw.mb s1 ] ] children

        Block.H6 ->
            Html.h6 [ classes [ Tw.type_caption, Tw.text_simple TC.textMuted, Tw.mt s2, Tw.mb s1 ] ] children


viewLink : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg
viewLink link children =
    Html.a
        [ Attr.href link.destination
        , classes
            [ Tw.text_simple TC.brand
            , Tw.type_body
            , Tw.underline
            , Tw.underline_offset_2
            , Bp.hover [ Tw.opacity_70 ]
            , Bp.withVariant "motion-safe" [ Tw.transition_opacity ]
            ]
        ]
        children


normalizeSrc : String -> String
normalizeSrc src =
    if
        String.startsWith "http://" src
            || String.startsWith "https://" src
            || String.startsWith "/" src
            || String.startsWith "data:" src
    then
        src

    else if String.startsWith "./" src then
        "/" ++ String.dropLeft 2 src

    else
        "/" ++ src


viewImage : { alt : String, src : String, title : Maybe String } -> Html msg
viewImage img =
    let
        ( maybeClass, altText ) =
            splitClassPrefix img.alt

        imageClasses =
            case maybeClass of
                Just "self-center" ->
                    Tw.batch [ Tw.mx_auto, Tw.w_4over6 ]

                Just "w-2" ->
                    Tw.w_4over6

                Just _ ->
                    Tw.batch []

                Nothing ->
                    Tw.batch []
    in
    Html.figure [ classes [ Tw.my s8 ] ]
        [ Html.img
            [ Attr.src (normalizeSrc img.src)
            , Attr.alt altText
            , classes [ imageClasses ]
            ]
            []
        , case img.title of
            Just title ->
                Html.figcaption [ classes [ Tw.mt s2, Tw.text_center, Tw.type_caption, Tw.text_simple TC.textMuted ] ]
                    [ Html.text title ]

            Nothing ->
                Html.text ""
        ]


viewUnorderedList : List (Block.ListItem (Html msg)) -> Html msg
viewUnorderedList items =
    Html.ul [ classes [ Tw.my s4, TwEx.space_y s1, Tw.list_disc, Tw.pl s6, Tw.text_simple TC.textPrimary ] ]
        (List.map
            (\(Block.ListItem task children) ->
                Html.li
                    [ classes
                        (case task of
                            Block.CompletedTask ->
                                [ Tw.line_through, Tw.text_simple TC.textSubtle ]

                            _ ->
                                []
                        )
                    ]
                    children
            )
            items
        )


viewOrderedList : Int -> List (List (Html msg)) -> Html msg
viewOrderedList startingIndex items =
    Html.ol
        [ classes [ Tw.my s4, TwEx.space_y s1, Tw.list_decimal, Tw.pl s6, Tw.text_simple TC.textPrimary ]
        , Attr.attribute "start" (String.fromInt startingIndex)
        ]
        (List.map (Html.li []) items)


viewCodeBlock : { body : String, language : Maybe String } -> Html msg
viewCodeBlock { body, language } =
    Html.div [ classes [ Tw.my s6, Tw.rounded_lg, Tw.overflow_hidden ] ]
        [ case language of
            Just lang ->
                Html.div [ classes [ Tw.px s4, Tw.py s1_dot_5, Tw.bg_simple TC.brand, TwEx.text_white_70, Tw.type_mono ] ]
                    [ Html.text lang ]

            Nothing ->
                Html.text ""
        , Html.pre
            [ classes [ Tw.bg_simple TC.brand, TwEx.text_white_90, Tw.p s4, Tw.overflow_x_auto, Tw.type_mono, Tw.leading_relaxed ] ]
            [ Html.code [] [ Html.text body ] ]
        ]


htmlRenderer : Markdown.Html.Renderer (List (Html msg) -> Html msg)
htmlRenderer =
    Markdown.Html.oneOf
        [ -- <callout type="info|success|warning|error">…</callout>
          Markdown.Html.tag "callout"
            (\calloutType children ->
                Alert.view
                    { alertType = parseAlertType calloutType
                    , title = Nothing
                    , body = children
                    , onDismiss = Nothing
                    }
            )
            |> Markdown.Html.withAttribute "type"
        , -- <hero title="…" subtitle="…">…</hero>
          Markdown.Html.tag "hero"
            (\title subtitle children ->
                Hero.view
                    { title = title
                    , subtitle = subtitle
                    , cta = children
                    }
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "subtitle"
        , -- <feature-grid columns="2|3">…</feature-grid>
          Markdown.Html.tag "feature-grid"
            (\columns children ->
                let
                    cols =
                        columns
                            |> Maybe.andThen String.toInt
                            |> Maybe.withDefault 3
                in
                Html.div
                    [ classes
                        ([ TwEx.not_prose
                         , Tw.grid
                         , Tw.gap_x s8
                         , Tw.gap_y s10
                         ]
                            ++ (case cols of
                                    2 ->
                                        [ Bp.sm [ Tw.grid_cols_2 ] ]

                                    3 ->
                                        [ Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_3 ] ]

                                    _ ->
                                        [ Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_4 ] ]
                               )
                        )
                    ]
                    children
            )
            |> Markdown.Html.withOptionalAttribute "columns"
        , -- <feature title="…" icon="…">…</feature>
          Markdown.Html.tag "feature"
            (\title icon children ->
                Html.div [ classes [ Tw.flex, Tw.flex_col ] ]
                    [ case icon of
                        Just ico ->
                            Html.div
                                [ classes [ Tw.mb s4, Tw.flex, Tw.h s10, Tw.w s10, Tw.items_center, Tw.justify_center, Tw.rounded_lg, Tw.bg_simple TC.brandYellow, Tw.text_simple TC.brand, Tw.type_h4 ] ]
                                [ Html.text ico ]

                        Nothing ->
                            Html.text ""
                    , Html.h3 [ classes [ Tw.type_h4, TwEx.leading_7, Tw.text_simple TC.textPrimary ] ]
                        [ Html.text title ]
                    , Html.div [ classes [ Tw.mt s2, Tw.type_caption, TwEx.leading_7, Tw.text_simple TC.textMuted ] ] children
                    ]
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "icon"
        , -- <pricing-table highlighted="Tier Name">…</pricing-table>
          Markdown.Html.tag "pricing-table"
            (\_ children ->
                Html.div
                    [ classes [ TwEx.not_prose, Tw.py s8, Tw.grid, Tw.gap s8, Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_3 ] ] ]
                    children
            )
            |> Markdown.Html.withOptionalAttribute "highlighted"
        , -- <pricing-tier name="…" price="…" period="…">…</pricing-tier>
          Markdown.Html.tag "pricing-tier"
            (\name price period children ->
                Html.div
                    [ classes [ Tw.rounded_2xl, Tw.border, Tw.border_simple TC.borderDefault, Tw.bg_simple white, Tw.shadow_sm, Tw.overflow_hidden ] ]
                    [ Html.div [ classes [ Tw.p s8 ] ]
                        [ Html.h3
                            [ classes [ Tw.type_h4, Tw.text_simple TC.textPrimary ] ]
                            [ Html.text name ]
                        , Html.div [ classes [ Tw.mt s4, Tw.flex, Tw.items_baseline, Tw.gap_x s2 ] ]
                            [ Html.span
                                [ classes [ Tw.type_display, Tw.tracking_tight, Tw.text_simple TC.textPrimary ] ]
                                [ Html.text price ]
                            , case period of
                                Just p ->
                                    Html.span
                                        [ classes [ Tw.type_body_small, Tw.text_simple TC.textMuted ] ]
                                        [ Html.text ("/ " ++ p) ]

                                Nothing ->
                                    Html.text ""
                            ]
                        , Html.div [ classes [ Tw.mt s8, Tw.type_caption, Tw.text_simple TC.textPrimary ] ] children
                        ]
                    ]
            )
            |> Markdown.Html.withAttribute "name"
            |> Markdown.Html.withAttribute "price"
            |> Markdown.Html.withOptionalAttribute "period"
        , -- <button-link href="…" variant="primary|secondary|ghost">label</button-link>
          Markdown.Html.tag "button-link"
            (\href variant children ->
                Html.a
                    [ Attr.href href
                    , classes (buttonLinkClasses variant)
                    ]
                    children
            )
            |> Markdown.Html.withAttribute "href"
            |> Markdown.Html.withOptionalAttribute "variant"
        , -- <card title="…">body</card>
          Markdown.Html.tag "card"
            (\title children ->
                Card.view
                    { header = Maybe.map (\t -> Html.span [ classes [ Tw.type_body_small, Tw.text_simple TC.textPrimary ] ] [ Html.text t ]) title
                    , body = children
                    , footer = Nothing
                    , image = Nothing
                    , shadow = Card.Sm
                    }
            )
            |> Markdown.Html.withOptionalAttribute "title"
        , -- <badge color="gray|blue|green|yellow|red|purple|indigo">label</badge>
          Markdown.Html.tag "badge"
            (\color children ->
                Html.span [ classes (badgeClasses color) ] children
            )
            |> Markdown.Html.withOptionalAttribute "color"
        , -- <accordion><accordion-item summary="…">…</accordion-item></accordion>
          Markdown.Html.tag "accordion"
            (\children -> Accordion.view children)
        , -- <accordion-item summary="…">…</accordion-item>
          Markdown.Html.tag "accordion-item"
            (\summary children ->
                Accordion.viewItem { title = summary, body = children }
            )
            |> Markdown.Html.withAttribute "summary"
        , -- <stat-grid><stat label="…" value="…" change="…"></stat></stat-grid>
          Markdown.Html.tag "stat-grid"
            (\children -> Stats.view children)
        , -- <stat label="…" value="…" change="…"></stat>
          Markdown.Html.tag "stat"
            (\label value change _ ->
                Stats.viewItem { label = label, value = value, change = change }
            )
            |> Markdown.Html.withAttribute "label"
            |> Markdown.Html.withAttribute "value"
            |> Markdown.Html.withOptionalAttribute "change"
        , -- <timeline><timeline-item date="…" title="…">…</timeline-item></timeline>
          Markdown.Html.tag "timeline"
            (\children -> Timeline.view children)
        , -- <timeline-item date="…" title="…" icon="…" image="…">…</timeline-item>
          Markdown.Html.tag "timeline-item"
            (\date title icon image children ->
                Timeline.viewItem { date = date, title = title, icon = Maybe.map (resolveIcon >> FeatherIcons.toHtml []) icon, image = image, children = children }
            )
            |> Markdown.Html.withAttribute "date"
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "icon"
            |> Markdown.Html.withOptionalAttribute "image"
        , -- <asset-gallery source="logos-square|logos-square-full|logos-horizontal" title="…" description="…"/>
          Markdown.Html.tag "asset-gallery"
            (\source title description _ ->
                viewAssetGallery source title description
            )
            |> Markdown.Html.withAttribute "source"
            |> Markdown.Html.withOptionalAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
        , -- <color-grid source="brand|skin-tones|rainbow" title="…" description="…"/>
          Markdown.Html.tag "color-grid"
            (\source title description _ ->
                viewColorGrid source title description
            )
            |> Markdown.Html.withAttribute "source"
            |> Markdown.Html.withOptionalAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
        , -- <info-panel color="amber|blue|green|red" title="…">…</info-panel>
          Markdown.Html.tag "info-panel"
            (\color title children ->
                viewInfoPanel color title children
            )
            |> Markdown.Html.withOptionalAttribute "color"
            |> Markdown.Html.withOptionalAttribute "title"
        , -- <with-image src="…" alt="…" side="left|right">…</with-image>
          Markdown.Html.tag "with-image"
            (\src alt side children ->
                let
                    imgEl =
                        Html.img
                            [ Attr.src (normalizeSrc src)
                            , Attr.alt (Maybe.withDefault "" alt)
                            , classes [ Tw.w_full, Tw.rounded_lg ]
                            ]
                            []

                    isRight =
                        Maybe.withDefault "right" side == "right"
                in
                Html.div
                    [ classes [ TwEx.not_prose, Tw.grid, Tw.grid_cols_1, Bp.md [ Tw.grid_cols_2 ], Tw.gap s8, Tw.items_center, Tw.my s8 ] ]
                    (if isRight then
                        [ Html.div [] children, Html.div [] [ imgEl ] ]

                     else
                        [ Html.div [] [ imgEl ], Html.div [] children ]
                    )
            )
            |> Markdown.Html.withAttribute "src"
            |> Markdown.Html.withOptionalAttribute "alt"
            |> Markdown.Html.withOptionalAttribute "side"
        , -- <spinner size="small|medium|large" label="…"/>
          Markdown.Html.tag "spinner"
            (\size label _ ->
                Spinner.view
                    { size = parseSpinnerSize size
                    , label = Maybe.withDefault "" label
                    }
            )
            |> Markdown.Html.withOptionalAttribute "size"
            |> Markdown.Html.withOptionalAttribute "label"
        , -- <progress-bar value="75" max="100" label="…" color="brand|success|warning|danger|info"/>
          Markdown.Html.tag "progress-bar"
            (\value max label color _ ->
                Progress.view
                    { value = value |> Maybe.andThen String.toInt |> Maybe.withDefault 0
                    , max = max |> Maybe.andThen String.toInt |> Maybe.withDefault 100
                    , label = label
                    , color = parseProgressColor color
                    }
            )
            |> Markdown.Html.withOptionalAttribute "value"
            |> Markdown.Html.withOptionalAttribute "max"
            |> Markdown.Html.withOptionalAttribute "label"
            |> Markdown.Html.withOptionalAttribute "color"
        , -- <section-header title="…" description="…"/>
          Markdown.Html.tag "section-header"
            (\title description _ ->
                SectionHeader.view
                    { title = title
                    , description = description
                    }
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
        , -- <section-subheader title="…" description="…"/>
          Markdown.Html.tag "section-subheader"
            (\title description _ ->
                SectionHeader.viewSub
                    { title = title
                    , description = description
                    }
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
        , -- <toast variant="default|success|warning|danger" title="…" body="…"/>
          Markdown.Html.tag "toast"
            (\variant title body _ ->
                Toast.view
                    { variant = parseToastVariant variant
                    , title = title
                    , body = Maybe.withDefault "" body
                    , onClose = Nothing
                    }
            )
            |> Markdown.Html.withOptionalAttribute "variant"
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "body"
        , -- <tag label="…"/>
          Markdown.Html.tag "tag"
            (\label _ ->
                Tag.view { label = label, onRemove = Nothing }
            )
            |> Markdown.Html.withAttribute "label"
        ]


parseAlertType : String -> Alert.AlertType
parseAlertType s =
    case s of
        "success" ->
            Alert.Success

        "warning" ->
            Alert.Warning

        "error" ->
            Alert.Error

        _ ->
            Alert.Info


badgeClasses : Maybe String -> List Tw.Tailwind
badgeClasses color =
    [ Tw.inline_flex
    , Tw.items_center
    , Tw.rounded_full
    , Tw.px s2_dot_5
    , Tw.py s0_dot_5
    , Tw.type_caption
    ]
        ++ (case Maybe.withDefault "gray" color of
                "blue" ->
                    [ TwEx.bg_brand_15, Tw.text_simple TC.brand ]

                "green" ->
                    [ Tw.bg_simple TC.brandNougatLight, Tw.text_simple TC.brandNougatDark ]

                "yellow" ->
                    [ TwEx.bg_brand_yellow_20, Tw.text_simple TC.brand ]

                "red" ->
                    [ TwEx.bg_brand_red_15, Tw.text_simple TC.brandRed ]

                "purple" ->
                    [ TwEx.bg_brand_15, Tw.text_simple TC.brand ]

                "indigo" ->
                    [ TwEx.bg_brand_20, Tw.text_simple TC.brand ]

                _ ->
                    [ Tw.bg_simple TC.bgSubtle, Tw.text_simple TC.textPrimary ]
           )


buttonLinkClasses : Maybe String -> List Tw.Tailwind
buttonLinkClasses variant =
    let
        base =
            [ Tw.no_underline
            , Tw.inline_flex
            , Tw.items_center
            , Tw.justify_center
            , Tw.type_body_small
            , Tw.rounded_lg
            , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
            , Bp.focus [ Tw.outline_none ]
            , Bp.focus_visible [ Tw.ring_2, Tw.ring_offset_2 ]
            , Tw.px s4
            , Tw.py s2
            , Tw.mr s2
            , Tw.mb s2
            , TwEx.p_text_inherit
            , TwEx.p_my_0
            ]
    in
    base
        ++ (case Maybe.withDefault "primary" variant of
                "secondary" ->
                    [ Tw.bg_simple white
                    , Tw.text_simple TC.brand
                    , Tw.border
                    , TwEx.border_brand_40
                    , Bp.hover [ TwEx.bg_brand_5 ]
                    , Bp.focus [ TwEx.ring_brand ]
                    ]

                "ghost" ->
                    [ Tw.text_simple TC.brand
                    , Bp.hover [ TwEx.bg_brand_5 ]
                    , Bp.focus [ TwEx.ring_brand ]
                    ]

                _ ->
                    [ Tw.bg_simple TC.brandYellow
                    , Tw.text_simple TC.brand
                    , Bp.hover [ Tw.bg_simple TC.brand, Tw.text_simple TC.brandYellow ]
                    , Bp.focus [ TwEx.ring_brand_yellow ]
                    ]
           )


viewAssetGallery : String -> Maybe String -> Maybe String -> Html msg
viewAssetGallery source maybeTitle maybeDescription =
    let
        cols =
            if source == "logos-horizontal" then
                Gallery.TwoWide

            else
                Gallery.Four
    in
    Gallery.view
        { title = Maybe.withDefault "" maybeTitle
        , description = maybeDescription
        , columns = cols
        , items = List.map LogoCard.view (logoItemsFromSource source)
        }


logoItemsFromSource : String -> List LogoCard.LogoVariant
logoItemsFromSource source =
    case source of
        "logos-square" ->
            Logos.squareVariants

        "logos-square-full" ->
            Logos.squareFullVariants

        "logos-horizontal" ->
            Logos.horizontalVariants

        _ ->
            []


viewColorGrid : String -> Maybe String -> Maybe String -> Html msg
viewColorGrid source maybeTitle maybeDescription =
    Gallery.view
        { title = Maybe.withDefault "" maybeTitle
        , description = maybeDescription
        , columns = Gallery.Four
        , items = List.map ColorSwatch.view (colorItemsFromSource source)
        }


colorItemsFromSource : String -> List ColorSwatch.ColorSwatchConfig
colorItemsFromSource source =
    case source of
        "brand" ->
            List.map (\c -> { hex = c.hex, name = c.name, description = c.description, usageTags = c.usage }) Colors.brandColors

        "skin-tones" ->
            List.map (\c -> { hex = c.hex, name = c.name, description = c.description, usageTags = [] }) Colors.skinTones

        "rainbow" ->
            List.map (\c -> { hex = c.hex, name = c.name, description = c.description, usageTags = [] }) Colors.rainbowColors

        _ ->
            []


viewInfoPanel : Maybe String -> Maybe String -> List (Html msg) -> Html msg
viewInfoPanel maybeColor maybeTitle children =
    let
        ( bgClass, borderClass, textClass ) =
            infoPanelColors (Maybe.withDefault "amber" maybeColor)
    in
    Html.div
        [ classes [ TwEx.not_prose, bgClass, Tw.border, borderClass, Tw.rounded_lg, Tw.p s4, Tw.text_sm, textClass, TwEx.space_y s2 ] ]
        (case maybeTitle of
            Just t ->
                Html.p [ classes [ Tw.font_semibold ] ] [ Html.text t ] :: children

            Nothing ->
                children
        )


infoPanelColors : String -> ( Tw.Tailwind, Tw.Tailwind, Tw.Tailwind )
infoPanelColors color =
    case color of
        "blue" ->
            ( Tw.bg_color (Th.blue Th.s50), Tw.border_color (Th.blue Th.s200), Tw.text_color (Th.blue Th.s800) )

        "green" ->
            ( Tw.bg_color (Th.green Th.s50), Tw.border_color (Th.green Th.s200), Tw.text_color (Th.green Th.s800) )

        "red" ->
            ( Tw.bg_color (Th.red Th.s50), Tw.border_color (Th.red Th.s200), Tw.text_color (Th.red Th.s800) )

        _ ->
            ( Tw.bg_color (Th.amber Th.s50), Tw.border_color (Th.amber Th.s200), Tw.text_color (Th.amber Th.s800) )


resolveIcon : String -> FeatherIcons.Icon
resolveIcon name =
    case name of
        "calendar" ->
            FeatherIcons.calendar

        "check" ->
            FeatherIcons.check

        "check-circle" ->
            FeatherIcons.checkCircle

        "circle" ->
            FeatherIcons.circle

        "clock" ->
            FeatherIcons.clock

        "flag" ->
            FeatherIcons.flag

        "map-pin" ->
            FeatherIcons.mapPin

        "star" ->
            FeatherIcons.star

        "users" ->
            FeatherIcons.users

        "zap" ->
            FeatherIcons.zap

        _ ->
            FeatherIcons.circle


parseSpinnerSize : Maybe String -> Spinner.Size
parseSpinnerSize s =
    case s of
        Just "small" ->
            Spinner.Small

        Just "large" ->
            Spinner.Large

        _ ->
            Spinner.Medium


parseProgressColor : Maybe String -> Progress.Color
parseProgressColor s =
    case s of
        Just "success" ->
            Progress.Success

        Just "warning" ->
            Progress.Warning

        Just "danger" ->
            Progress.Danger

        Just "info" ->
            Progress.Info

        _ ->
            Progress.Brand


parseToastVariant : Maybe String -> Toast.Variant
parseToastVariant s =
    case s of
        Just "success" ->
            Toast.Success

        Just "warning" ->
            Toast.Warning

        Just "danger" ->
            Toast.Danger

        _ ->
            Toast.Default
