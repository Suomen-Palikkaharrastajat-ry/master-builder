module MarkdownRenderer.HtmlTags exposing (htmlRenderer)

{-| Custom HTML tag rendering for markdown content.
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
import Component.Toc as Toc
import ContentMarkdown exposing (TocNode)
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Lazy
import Markdown.Html
import MarkdownRenderer.Helpers as Helpers
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th exposing (s0_dot_5, s1, s10, s1_dot_5, s2, s2_dot_5, s3, s4, s6, s8, white)
import TailwindExtra as TwEx
import TailwindTokens as TC


htmlRenderer : { childPages : List TocNode, sectionSlug : Maybe String } -> Markdown.Html.Renderer (List (Html msg) -> Html msg)
htmlRenderer context =
    Markdown.Html.oneOf
        [ -- <callout type="info|success|warning|error" icon="…">…</callout>
          Markdown.Html.tag "callout"
            (\calloutType iconName children ->
                Alert.view
                    { alertType = parseAlertType calloutType
                    , title = Nothing
                    , body = children
                    , onDismiss = Nothing
                    , customIcon =
                        Maybe.map
                            (\name ->
                                resolveIcon name
                                    |> FeatherIcons.withSize 18
                                    |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true" ]
                            )
                            iconName
                    }
            )
            |> Markdown.Html.withAttribute "type"
            |> Markdown.Html.withOptionalAttribute "icon"
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
        , -- <feature title="…" icon="…" href="…">…</feature>
          Markdown.Html.tag "feature"
            (\title icon href children ->
                let
                    renderedIcon =
                        icon
                            |> Maybe.map
                                (\name ->
                                    Html.div
                                        [ classes [ Tw.mb s4, Tw.flex, Tw.h s10, Tw.w s10, Tw.items_center, Tw.justify_center, Tw.rounded_lg, Tw.bg_simple TC.brandYellow, Tw.text_simple TC.brand ] ]
                                        [ resolveIcon name |> FeatherIcons.withSize 22 |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true" ] ]
                                )

                    content =
                        [ Maybe.withDefault (Html.text "") renderedIcon
                        , Html.h3 [ classes [ Tw.type_h4, TwEx.leading_7, Tw.text_simple TC.textPrimary ] ]
                            [ Html.text title ]
                        , Html.div [ classes [ Tw.mt s2, Tw.type_caption, TwEx.leading_7, Tw.text_simple TC.textMuted, TwEx.p_my_0, TwEx.p_text_inherit ] ] children
                        ]
                in
                case href of
                    Just url ->
                        Html.a
                            ([ Attr.href url
                             , classes
                                [ Tw.flex
                                , Tw.flex_col
                                , Tw.no_underline
                                , Tw.rounded_lg
                                , Tw.p s3
                                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                                , Bp.hover [ TwEx.bg_brand_5, Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                                , Bp.focus [ Tw.outline_none ]
                                , Bp.focus_visible [ Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                                ]
                             ]
                                ++ Helpers.externalLinkAttrs url
                            )
                            content

                    Nothing ->
                        Html.div [ classes [ Tw.flex, Tw.flex_col ] ] content
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "icon"
            |> Markdown.Html.withOptionalAttribute "href"
        , -- <pricing-table highlighted="Tier Name">…</pricing-table>
          Markdown.Html.tag "pricing-table"
            (\_ children ->
                Html.div
                    [ classes [ TwEx.not_prose, Tw.py s8, Tw.grid, Tw.gap s8, Bp.sm [ Tw.grid_cols_2 ], Bp.lg [ Tw.grid_cols_3 ] ] ]
                    children
            )
            |> Markdown.Html.withOptionalAttribute "highlighted"
        , -- <pricing-tier name="…" price="…" period="…" href="…">…</pricing-tier>
          Markdown.Html.tag "pricing-tier"
            (\name price period href children ->
                let
                    inner =
                        Html.div [ classes [ Tw.p s8 ] ]
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
                            , Html.div
                                [ classes
                                    [ Tw.mt s8
                                    , Tw.type_caption
                                    , Tw.text_simple TC.textPrimary
                                    , TwEx.ul_list_none
                                    , TwEx.ul_pl_0
                                    , TwEx.ul_my_0
                                    , TwEx.ul_space_y_2
                                    , TwEx.li_flex
                                    , TwEx.li_items_center
                                    , TwEx.li_gap_2
                                    , TwEx.li_before_content_check
                                    , TwEx.li_before_text_brand_yellow
                                    ]
                                ]
                                children
                            ]
                in
                case href of
                    Just url ->
                        Html.a
                            ([ Attr.href url
                             , classes
                                [ Tw.block
                                , Tw.no_underline
                                , Tw.rounded_2xl
                                , Tw.border
                                , Tw.border_simple TC.borderDefault
                                , Tw.bg_simple white
                                , Tw.shadow_sm
                                , Tw.overflow_hidden
                                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                                , Bp.hover [ TwEx.bg_brand_5, Tw.border_simple TC.brand, Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                                , Bp.focus [ Tw.outline_none ]
                                , Bp.focus_visible [ Tw.ring_2, Tw.ring_offset_2, TwEx.ring_brand ]
                                ]
                             ]
                                ++ Helpers.externalLinkAttrs url
                            )
                            [ inner ]

                    Nothing ->
                        Html.div
                            [ classes [ Tw.rounded_2xl, Tw.border, Tw.border_simple TC.borderDefault, Tw.bg_simple white, Tw.shadow_sm, Tw.overflow_hidden ] ]
                            [ inner ]
            )
            |> Markdown.Html.withAttribute "name"
            |> Markdown.Html.withAttribute "price"
            |> Markdown.Html.withOptionalAttribute "period"
            |> Markdown.Html.withOptionalAttribute "href"
        , -- <button-link href="…" variant="primary|secondary|ghost" label="…"/>
          Markdown.Html.tag "button-link"
            (\href variant label _ ->
                Html.a
                    ([ Attr.href href
                     , classes (buttonLinkClasses variant)
                     ]
                        ++ Helpers.externalLinkAttrs href
                    )
                    [ Html.text label ]
            )
            |> Markdown.Html.withAttribute "href"
            |> Markdown.Html.withOptionalAttribute "variant"
            |> Markdown.Html.withAttribute "label"
        , -- <card title="…">body</card>
          Markdown.Html.tag "card"
            (\title children ->
                Card.view
                    { header = Maybe.map (\t -> Html.span [ classes [ Tw.type_h4, Tw.text_simple TC.brand ] ] [ Html.text t ]) title
                    , body = children
                    , footer = Nothing
                    , image = Nothing
                    , shadow = Card.Sm
                    }
            )
            |> Markdown.Html.withOptionalAttribute "title"
        , -- <badge color="gray|blue|green|yellow|red|purple|indigo" label="…"/>
          Markdown.Html.tag "badge"
            (\color label _ ->
                Html.span [ classes (badgeClasses color) ] [ Html.text label ]
            )
            |> Markdown.Html.withOptionalAttribute "color"
            |> Markdown.Html.withAttribute "label"
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
        , -- <gallery title="…" description="…" columns="2|3|4|2-wide">…</gallery>
          Markdown.Html.tag "gallery"
            (\title description columns children ->
                Gallery.view
                    { title = title
                    , description = description
                    , columns = parseGalleryColumns columns
                    , items = children
                    }
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
            |> Markdown.Html.withOptionalAttribute "columns"
        , -- <gallery-item id="…" description="…" ... />
          Markdown.Html.tag "gallery-item"
            (\id description theme animated withText bold highlight svg png webp gif _ ->
                LogoCard.view
                    { id = id
                    , description = description
                    , theme = Maybe.withDefault "light" theme
                    , animated = parseBoolAttribute animated
                    , withText = parseBoolAttribute withText
                    , bold = parseBoolAttribute bold
                    , highlight = parseBoolAttribute highlight
                    , svgUrl = svg
                    , pngUrl = png
                    , webpUrl = webp
                    , gifUrl = gif
                    }
            )
            |> Markdown.Html.withAttribute "id"
            |> Markdown.Html.withAttribute "description"
            |> Markdown.Html.withOptionalAttribute "theme"
            |> Markdown.Html.withOptionalAttribute "animated"
            |> Markdown.Html.withOptionalAttribute "with-text"
            |> Markdown.Html.withOptionalAttribute "bold"
            |> Markdown.Html.withOptionalAttribute "highlight"
            |> Markdown.Html.withOptionalAttribute "svg"
            |> Markdown.Html.withOptionalAttribute "png"
            |> Markdown.Html.withOptionalAttribute "webp"
            |> Markdown.Html.withOptionalAttribute "gif"
        , -- <color-grid title="…" description="…" columns="2|3|4">…</color-grid>
          Markdown.Html.tag "color-grid"
            (\title description columns children ->
                Gallery.view
                    { title = title
                    , description = description
                    , columns = parseGalleryColumns columns
                    , items = children
                    }
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "description"
            |> Markdown.Html.withOptionalAttribute "columns"
        , -- <color-grid-item name="…" hex="#…" description="…" usage="a,b,c"/>
          Markdown.Html.tag "color-grid-item"
            (\name hex description usage _ ->
                ColorSwatch.view
                    { hex = hex
                    , name = name
                    , description = Maybe.withDefault "" description
                    , usageTags = parseUsageTags usage
                    }
            )
            |> Markdown.Html.withAttribute "name"
            |> Markdown.Html.withAttribute "hex"
            |> Markdown.Html.withOptionalAttribute "description"
            |> Markdown.Html.withOptionalAttribute "usage"
        , -- <info-panel color="amber|blue|green|red" title="…" icon="…">…</info-panel>
          Markdown.Html.tag "info-panel"
            (\color title icon children ->
                viewInfoPanel color title icon children
            )
            |> Markdown.Html.withOptionalAttribute "color"
            |> Markdown.Html.withOptionalAttribute "title"
            |> Markdown.Html.withOptionalAttribute "icon"
        , -- <clear> — inserts a float-clearing div
          Markdown.Html.tag "clear"
            (\_ -> Html.div [ classes [ Tw.clear_both ] ] [])
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
        , -- <search livesearch="true" /> — inline search widget; defaults to normal /haku navigation.
          Markdown.Html.tag "search"
            (\liveSearch _ ->
                viewSearchWidget (parseBoolAttribute liveSearch)
            )
            |> Markdown.Html.withOptionalAttribute "livesearch"
        , -- <tab-group name="…"><preview>…</preview><example>…</example></tab-group>
          Markdown.Html.tag "tab-group"
            (\name children ->
                Html.div
                    [ Attr.class "tab-group not-prose my-8 rounded-lg border overflow-hidden"
                    , Attr.style "border-color" "var(--color-border-default)"
                    ]
                    ([ Html.input
                        [ Attr.type_ "radio"
                        , Attr.id (name ++ "-p")
                        , Attr.name name
                        , Attr.attribute "checked" ""
                        ]
                        []
                     , Html.input
                        [ Attr.type_ "radio"
                        , Attr.id (name ++ "-c")
                        , Attr.name name
                        ]
                        []
                     , Html.div
                        [ Attr.class "tab-bar flex"
                        , Attr.style "border-bottom" "1px solid var(--color-border-default)"
                        ]
                        [ Html.label
                            [ Attr.for (name ++ "-p")
                            , Attr.class "tab-preview-label cursor-pointer px-4 py-2.5 text-sm font-medium border-b-2 border-transparent"
                            , Attr.style "color" "var(--color-text-muted)"
                            ]
                            [ Html.text "Preview" ]
                        , Html.label
                            [ Attr.for (name ++ "-c")
                            , Attr.class "tab-code-label cursor-pointer px-4 py-2.5 text-sm font-medium border-b-2 border-transparent"
                            , Attr.style "color" "var(--color-text-muted)"
                            ]
                            [ Html.text "Example" ]
                        ]
                     ]
                        ++ children
                    )
            )
            |> Markdown.Html.withAttribute "name"
        , -- <preview>…</preview> (used inside <tab-group>)
          Markdown.Html.tag "preview"
            (\children ->
                Html.div [ Attr.class "tab-panel-preview p-6 space-y-4" ] children
            )
        , -- <example>…</example> (used inside <tab-group>)
          Markdown.Html.tag "example"
            (\children ->
                Html.div [ Attr.class "tab-panel-code" ] children
            )
        , -- <toc depth="N" /> — auto-generated table of contents (default: all levels)
          Markdown.Html.tag "toc"
            (\depthAttr _ ->
                let
                    maxDepth =
                        depthAttr
                            |> Maybe.andThen String.toInt
                            |> Maybe.withDefault 99
                in
                case context.sectionSlug of
                    Just section ->
                        let
                            nodeHref fm =
                                if String.isEmpty section then
                                    "/" ++ fm.slug

                                else
                                    "/" ++ section ++ "/" ++ fm.slug

                            toTocItem node =
                                let
                                    fm =
                                        node.frontmatter

                                    selfHref =
                                        nodeHref fm
                                in
                                { title = fm.title
                                , href = selfHref
                                , description = fm.description
                                , children =
                                    if maxDepth <= 1 then
                                        []

                                    else
                                        List.map
                                            (\childFm ->
                                                { title = childFm.title
                                                , href = selfHref ++ "/" ++ childFm.slug
                                                }
                                            )
                                            node.sectionChildren
                                }
                        in
                        Toc.view (List.map toTocItem context.childPages)

                    Nothing ->
                        Html.text ""
            )
            |> Markdown.Html.withOptionalAttribute "depth"
        , -- <bricks-viewer src="…" controls float="left|right" max-width="400px" camera-azimuth="…" …></bricks-viewer>
          -- float="left|right"  — floats the viewer so prose text wraps around it.
          -- Not set             — ml-auto (right-aligned block, no text wrapping).
          -- max-width           — any CSS value, e.g. "400px" or "40%".
          -- Html.Lazy.lazy prevents Elm's vdom from re-diffing this subtree on every
          -- Shared re-render (menu toggle etc.), which would otherwise remove children
          -- appended to the light DOM by the bricks-viewer script.
          Markdown.Html.tag "bricks-viewer"
            (\src controls azimuth elevation distance tx ty tz motorIndex rpm float maxWidth _ ->
                let
                    viewerAttrs =
                        { src = src
                        , controls = controls
                        , azimuth = azimuth
                        , elevation = elevation
                        , distance = distance
                        , tx = tx
                        , ty = ty
                        , tz = tz
                        , motorIndex = motorIndex
                        , rpm = rpm
                        }

                    viewer =
                        Html.Lazy.lazy
                            (\a ->
                                Html.node "bricks-viewer"
                                    (List.filterMap identity
                                        [ Maybe.map (Attr.attribute "src") a.src
                                        , Maybe.map (\_ -> Attr.attribute "controls" "") a.controls
                                        , Maybe.map (Attr.attribute "camera-azimuth") a.azimuth
                                        , Maybe.map (Attr.attribute "camera-elevation") a.elevation
                                        , Maybe.map (Attr.attribute "camera-distance") a.distance
                                        , Maybe.map (Attr.attribute "camera-target-x") a.tx
                                        , Maybe.map (Attr.attribute "camera-target-y") a.ty
                                        , Maybe.map (Attr.attribute "camera-target-z") a.tz
                                        , Maybe.map (Attr.attribute "motor-index") a.motorIndex
                                        , Maybe.map (Attr.attribute "rpm") a.rpm
                                        ]
                                    )
                                    []
                            )
                            viewerAttrs

                    floatClasses =
                        case float of
                            Just "left" ->
                                [ TwEx.not_prose, Tw.float_left, Tw.mr s6, Tw.mb s4 ]

                            Just "right" ->
                                [ TwEx.not_prose, Tw.float_right, Tw.ml s6, Tw.mb s4 ]

                            _ ->
                                [ TwEx.not_prose, Tw.ml_auto, Tw.mb s4 ]

                in
                Html.div
                    (classes floatClasses
                        :: (case maxWidth of
                                Just w ->
                                    [ Attr.style "max-width" w ]

                                Nothing ->
                                    []
                           )
                    )
                    [ viewer ]
            )
            |> Markdown.Html.withOptionalAttribute "src"
            |> Markdown.Html.withOptionalAttribute "controls"
            |> Markdown.Html.withOptionalAttribute "camera-azimuth"
            |> Markdown.Html.withOptionalAttribute "camera-elevation"
            |> Markdown.Html.withOptionalAttribute "camera-distance"
            |> Markdown.Html.withOptionalAttribute "camera-target-x"
            |> Markdown.Html.withOptionalAttribute "camera-target-y"
            |> Markdown.Html.withOptionalAttribute "camera-target-z"
            |> Markdown.Html.withOptionalAttribute "motor-index"
            |> Markdown.Html.withOptionalAttribute "rpm"
            |> Markdown.Html.withOptionalAttribute "float"
            |> Markdown.Html.withOptionalAttribute "max-width"
        ]


viewSearchWidget : Bool -> Html msg
viewSearchWidget liveSearch =
    Html.section
        (classes
            [ TwEx.not_prose
            , Tw.my s8
            , TwEx.max_w_2xl
            ]
            :: (if liveSearch then
                    [ Attr.attribute "data-search-widget" "true" ]

                else
                    []
               )
        )
        (Html.form
            ([ Attr.action "/haku"
             , Attr.method "GET"
             ]
                ++ (if liveSearch then
                        [ Attr.attribute "data-search-widget-form" "true" ]

                    else
                        []
                   )
                ++ [ classes [ Tw.flex, Tw.items_center, Tw.gap s2 ] ]
            )
            [ Html.label [ classes [ Tw.sr_only ] ] [ Html.text "Hae sivustolta" ]
            , Html.input
                ([ Attr.name "q"
                 , Attr.type_ "search"
                 , Attr.placeholder "Hae sivustolta"
                 , Attr.attribute "autocomplete" "off"
                 , Attr.attribute "data-search-widget-autofocus" "true"
                 ]
                    ++ (if liveSearch then
                            [ Attr.attribute "data-search-widget-input" "true" ]

                        else
                            []
                       )
                    ++ [ classes
                            [ Tw.w_full
                            , Tw.rounded_md
                            , Tw.border
                            , Tw.border_simple TC.borderBrand
                            , Tw.bg_simple TC.bgPage
                            , Tw.px s2
                            , Tw.py s1
                            , Tw.type_body_small
                            , Tw.text_simple TC.textPrimary
                            , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
                            ]
                       ]
                )
                []
            , Html.button
                [ Attr.type_ "submit"
                , classes
                    [ Tw.rounded_md
                    , Tw.border
                    , Tw.border_simple TC.brandYellow
                    , Tw.bg_simple TC.brandYellow
                    , Tw.px s2
                    , Tw.py s1
                    , Tw.type_body_small
                    , Tw.text_simple TC.brand
                    , Tw.cursor_pointer
                    , Bp.hover [ Tw.text_simple TC.brand ]
                    , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                    ]
                ]
                [ FeatherIcons.search |> FeatherIcons.withSize 16 |> FeatherIcons.toHtml [] ]
            ]
            :: (if liveSearch then
                    [ Html.div
                        [ Attr.attribute "data-search-widget-results" "true"
                        , Attr.class "search-widget-results"
                        , Attr.attribute "aria-live" "polite"
                        ]
                        [ Html.p [ Attr.class "search-widget-hint" ]
                            [ Html.text "Kirjoita hakusana ja tulokset päivittyvät automaattisesti." ]
                        ]
                    ]

                else
                    []
               )
        )


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


parseGalleryColumns : Maybe String -> Gallery.Columns
parseGalleryColumns maybeColumns =
    case maybeColumns of
        Just "2" ->
            Gallery.Two

        Just "3" ->
            Gallery.Three

        Just "2-wide" ->
            Gallery.TwoWide

        _ ->
            Gallery.Four


parseBoolAttribute : Maybe String -> Bool
parseBoolAttribute maybeValue =
    case maybeValue of
        Just "true" ->
            True

        Just "1" ->
            True

        Just "yes" ->
            True

        _ ->
            False


parseUsageTags : Maybe String -> List String
parseUsageTags maybeTags =
    maybeTags
        |> Maybe.map
            (\tags ->
                tags
                    |> String.split ","
                    |> List.map String.trim
                    |> List.filter (\tag -> not (String.isEmpty tag))
            )
        |> Maybe.withDefault []


viewInfoPanel : Maybe String -> Maybe String -> Maybe String -> List (Html msg) -> Html msg
viewInfoPanel maybeColor maybeTitle maybeIcon children =
    let
        ( bgClass, borderClass, textClass ) =
            infoPanelColors (Maybe.withDefault "amber" maybeColor)

        iconEl =
            case maybeIcon of
                Just iconName ->
                    resolveIcon iconName
                        |> FeatherIcons.withSize 18
                        |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true" ]

                Nothing ->
                    Html.text ""

        headerEl t =
            Html.div [ classes [ Tw.flex, Tw.items_center, Tw.gap s2, Tw.font_semibold ] ]
                [ iconEl, Html.span [] [ Html.text t ] ]
    in
    Html.div
        [ classes [ TwEx.not_prose, bgClass, Tw.border, borderClass, Tw.rounded_lg, Tw.p s4, Tw.text_sm, textClass, TwEx.space_y s2 ] ]
        (case maybeTitle of
            Just t ->
                headerEl t :: children

            Nothing ->
                case maybeIcon of
                    Just _ ->
                        Html.div [ classes [ Tw.flex, Tw.items_center ] ] [ iconEl ] :: children

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

        "code" ->
            FeatherIcons.code

        "cpu" ->
            FeatherIcons.cpu

        "edit" ->
            FeatherIcons.edit

        "git-branch" ->
            FeatherIcons.gitBranch

        "globe" ->
            FeatherIcons.globe

        "layers" ->
            FeatherIcons.layers

        "lock" ->
            FeatherIcons.lock

        "package" ->
            FeatherIcons.package

        "rss" ->
            FeatherIcons.rss

        "shield" ->
            FeatherIcons.shield

        "trending-up" ->
            FeatherIcons.trendingUp

        "alert-circle" ->
            FeatherIcons.alertCircle

        "alert-triangle" ->
            FeatherIcons.alertTriangle

        "bell" ->
            FeatherIcons.bell

        "bookmark" ->
            FeatherIcons.bookmark

        "database" ->
            FeatherIcons.database

        "download" ->
            FeatherIcons.download

        "external-link" ->
            FeatherIcons.externalLink

        "eye" ->
            FeatherIcons.eye

        "file" ->
            FeatherIcons.file

        "hash" ->
            FeatherIcons.hash

        "heart" ->
            FeatherIcons.heart

        "home" ->
            FeatherIcons.home

        "info" ->
            FeatherIcons.info

        "key" ->
            FeatherIcons.key

        "link" ->
            FeatherIcons.link

        "mail" ->
            FeatherIcons.mail

        "message-circle" ->
            FeatherIcons.messageCircle

        "search" ->
            FeatherIcons.search

        "send" ->
            FeatherIcons.send

        "server" ->
            FeatherIcons.server

        "settings" ->
            FeatherIcons.settings

        "tag" ->
            FeatherIcons.tag

        "terminal" ->
            FeatherIcons.terminal

        "tool" ->
            FeatherIcons.tool

        "trash" ->
            FeatherIcons.trash

        "upload" ->
            FeatherIcons.upload

        "user" ->
            FeatherIcons.user

        "x-circle" ->
            FeatherIcons.xCircle

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
