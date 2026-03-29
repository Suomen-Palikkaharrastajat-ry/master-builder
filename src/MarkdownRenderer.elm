module MarkdownRenderer exposing (renderMarkdown)

import Component.Accordion as Accordion
import Component.Alert as Alert
import Component.Card as Card
import Component.Hero as Hero
import Component.Stats as Stats
import Component.Timeline as Timeline
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer


renderMarkdown : String -> Html msg
renderMarkdown markdown =
    case
        markdown
            |> Markdown.Parser.parse
            |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
            |> Result.andThen (Markdown.Renderer.render renderer)
    of
        Ok rendered ->
            Html.article [ Attr.class "prose prose-gray max-w-none" ] rendered

        Err err ->
            Html.pre [ Attr.class "text-brand-red type-caption p-4 bg-brand-red/10 rounded" ] [ Html.text err ]


{-| Custom renderer — no explicit type annotation so Elm can freely unify the
`msg` type variable across all fields.
-}
renderer =
    { heading = viewHeading
    , paragraph = Html.p [ Attr.class "my-4 leading-7 text-text-primary" ]
    , hardLineBreak = Html.br [] []
    , blockQuote =
        \children ->
            Html.blockquote
                [ Attr.class "pl-4 border-l-4 border-border-default text-text-muted italic my-6" ]
                children
    , strong = \children -> Html.strong [ Attr.class "type-body-small text-text-primary" ] children
    , emphasis = \children -> Html.em [ Attr.class "italic" ] children
    , strikethrough = \children -> Html.s [] children
    , codeSpan =
        \code ->
            Html.code
                [ Attr.class "px-1.5 py-0.5 rounded bg-bg-subtle text-text-primary type-mono" ]
                [ Html.text code ]
    , link = viewLink
    , image = viewImage
    , text = Html.text
    , unorderedList = viewUnorderedList
    , orderedList = viewOrderedList
    , codeBlock = viewCodeBlock
    , thematicBreak = Html.hr [ Attr.class "my-8 border-border-default" ] []
    , table = Html.table [ Attr.class "w-full type-caption border-collapse my-6 rounded overflow-hidden" ]
    , tableHeader = Html.thead [ Attr.class "bg-bg-subtle border-b border-border-default" ]
    , tableBody = Html.tbody []
    , tableRow = Html.tr [ Attr.class "border-b border-border-default last:border-0" ]
    , tableHeaderCell =
        \_ children ->
            Html.th [ Attr.class "px-4 py-2 text-left type-body-small text-text-muted" ] children
    , tableCell =
        \_ children ->
            Html.td [ Attr.class "px-4 py-2 text-text-primary" ] children
    , html = htmlRenderer
    }


viewHeading :
    { level : Block.HeadingLevel, rawText : String, children : List (Html msg) }
    -> Html msg
viewHeading { level, children } =
    case level of
        Block.H1 ->
            Html.h1 [ Attr.class "type-h1 tracking-tight text-text-primary mt-8 mb-4" ] children

        Block.H2 ->
            Html.h2 [ Attr.class "type-h2 text-text-primary mt-8 mb-3 border-b border-border-default pb-2" ] children

        Block.H3 ->
            Html.h3 [ Attr.class "type-h3 text-text-primary mt-6 mb-2" ] children

        Block.H4 ->
            Html.h4 [ Attr.class "type-h4 text-text-primary mt-4 mb-1" ] children

        Block.H5 ->
            Html.h5 [ Attr.class "type-overline text-text-muted mt-3 mb-1" ] children

        Block.H6 ->
            Html.h6 [ Attr.class "type-caption text-text-muted mt-2 mb-1" ] children


viewLink : { title : Maybe String, destination : String } -> List (Html msg) -> Html msg
viewLink link children =
    Html.a
        [ Attr.href link.destination
        , Attr.class "text-brand type-body-small underline underline-offset-2 hover:opacity-70 motion-safe:transition-opacity"
        ]
        children


normalizeSrc : String -> String
normalizeSrc src =
    if String.startsWith "http://" src
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
    Html.figure [ Attr.class "my-8" ]
        [ Html.img
            [ Attr.src (normalizeSrc img.src)
            , Attr.alt img.alt
            , Attr.class "rounded-lg w-full"
            ]
            []
        , case img.title of
            Just title ->
                Html.figcaption [ Attr.class "mt-2 text-center type-caption text-text-muted" ]
                    [ Html.text title ]

            Nothing ->
                Html.text ""
        ]


viewUnorderedList : List (Block.ListItem (Html msg)) -> Html msg
viewUnorderedList items =
    Html.ul [ Attr.class "my-4 space-y-1 list-disc pl-6 text-text-primary" ]
        (List.map
            (\(Block.ListItem task children) ->
                Html.li
                    [ Attr.class
                        (case task of
                            Block.CompletedTask ->
                                "line-through text-text-subtle"

                            _ ->
                                ""
                        )
                    ]
                    children
            )
            items
        )


viewOrderedList : Int -> List (List (Html msg)) -> Html msg
viewOrderedList startingIndex items =
    Html.ol
        [ Attr.class "my-4 space-y-1 list-decimal pl-6 text-text-primary"
        , Attr.attribute "start" (String.fromInt startingIndex)
        ]
        (List.map (Html.li []) items)


viewCodeBlock : { body : String, language : Maybe String } -> Html msg
viewCodeBlock { body, language } =
    Html.div [ Attr.class "my-6 rounded-lg overflow-hidden" ]
        [ case language of
            Just lang ->
                Html.div [ Attr.class "px-4 py-1.5 bg-brand text-white/70 type-mono" ]
                    [ Html.text lang ]

            Nothing ->
                Html.text ""
        , Html.pre
            [ Attr.class "bg-brand text-white/90 p-4 overflow-x-auto type-mono leading-relaxed" ]
            [ Html.code [] [ Html.text body ] ]
        ]


{-| No explicit type annotation — lets Elm freely infer and unify `msg`.
-}
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
                    [ Attr.class
                        ("not-prose grid gap-x-8 gap-y-10 "
                            ++ (case cols of
                                    2 ->
                                        "sm:grid-cols-2"

                                    3 ->
                                        "sm:grid-cols-2 lg:grid-cols-3"

                                    _ ->
                                        "sm:grid-cols-2 lg:grid-cols-4"
                               )
                        )
                    ]
                    children
            )
            |> Markdown.Html.withOptionalAttribute "columns"
        , -- <feature title="…" icon="…">…</feature>
          Markdown.Html.tag "feature"
            (\title icon children ->
                Html.div [ Attr.class "flex flex-col" ]
                    [ case icon of
                        Just ico ->
                            Html.div
                                [ Attr.class "mb-4 flex h-10 w-10 items-center justify-center rounded-lg bg-brand-yellow text-brand type-h4" ]
                                [ Html.text ico ]

                        Nothing ->
                            Html.text ""
                    , Html.h3 [ Attr.class "type-h4 leading-7 text-text-primary" ]
                        [ Html.text title ]
                    , Html.div [ Attr.class "mt-2 type-caption leading-7 text-text-muted" ] children
                    ]
            )
            |> Markdown.Html.withAttribute "title"
            |> Markdown.Html.withOptionalAttribute "icon"
        , -- <pricing-table highlighted="Tier Name">…</pricing-table>
          Markdown.Html.tag "pricing-table"
            (\_ children ->
                Html.div
                    [ Attr.class "not-prose py-8 grid gap-8 sm:grid-cols-2 lg:grid-cols-3" ]
                    children
            )
            |> Markdown.Html.withOptionalAttribute "highlighted"
        , -- <pricing-tier name="…" price="…" period="…">…</pricing-tier>
          Markdown.Html.tag "pricing-tier"
            (\name price period children ->
                Html.div
                    [ Attr.class "rounded-2xl border border-border-default bg-white shadow-sm overflow-hidden" ]
                    [ Html.div [ Attr.class "p-8" ]
                        [ Html.h3
                            [ Attr.class "type-h4 text-text-primary" ]
                            [ Html.text name ]
                        , Html.div [ Attr.class "mt-4 flex items-baseline gap-x-2" ]
                            [ Html.span
                                [ Attr.class "type-display tracking-tight text-text-primary" ]
                                [ Html.text price ]
                            , case period of
                                Just p ->
                                    Html.span
                                        [ Attr.class "type-body-small text-text-muted" ]
                                        [ Html.text ("/ " ++ p) ]

                                Nothing ->
                                    Html.text ""
                            ]
                        , Html.div [ Attr.class "mt-8 type-caption text-text-primary" ] children
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
                    , Attr.class (buttonLinkClass variant)
                    ]
                    children
            )
            |> Markdown.Html.withAttribute "href"
            |> Markdown.Html.withOptionalAttribute "variant"
        , -- <card title="…">body</card>
          Markdown.Html.tag "card"
            (\title children ->
                Card.view
                    { header = Maybe.map (\t -> Html.span [ Attr.class "type-body-small text-text-primary" ] [ Html.text t ]) title
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
                Html.span [ Attr.class (badgeClass color) ] children
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
        , -- <with-image src="…" alt="…" side="left|right">…</with-image>
          Markdown.Html.tag "with-image"
            (\src alt side children ->
                let
                    imgEl =
                        Html.img
                            [ Attr.src (normalizeSrc src)
                            , Attr.alt (Maybe.withDefault "" alt)
                            , Attr.class "w-full rounded-lg"
                            ]
                            []

                    isRight =
                        Maybe.withDefault "right" side == "right"
                in
                Html.div
                    [ Attr.class "not-prose grid grid-cols-1 md:grid-cols-2 gap-8 items-center my-8" ]
                    (if isRight then
                        [ Html.div [] children, Html.div [] [ imgEl ] ]

                     else
                        [ Html.div [] [ imgEl ], Html.div [] children ]
                    )
            )
            |> Markdown.Html.withAttribute "src"
            |> Markdown.Html.withOptionalAttribute "alt"
            |> Markdown.Html.withOptionalAttribute "side"
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


badgeClass : Maybe String -> String
badgeClass color =
    "inline-flex items-center rounded-full px-2.5 py-0.5 type-caption "
        ++ (case Maybe.withDefault "gray" color of
                "blue" ->
                    "bg-brand/15 text-brand"

                "green" ->
                    "bg-brand-nougat-light text-brand-nougat-dark"

                "yellow" ->
                    "bg-brand-yellow/20 text-brand"

                "red" ->
                    "bg-brand-red/15 text-brand-red"

                "purple" ->
                    "bg-brand/15 text-brand"

                "indigo" ->
                    "bg-brand/20 text-brand"

                _ ->
                    "bg-bg-subtle text-text-primary"
           )


buttonLinkClass : Maybe String -> String
buttonLinkClass variant =
    let
        base =
            "no-underline inline-flex items-center justify-center type-body-small rounded-lg motion-safe:transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 px-4 py-2 mr-2 mb-2 [&_p]:text-inherit [&_p]:my-0"
    in
    base
        ++ " "
        ++ (case Maybe.withDefault "primary" variant of
                "secondary" ->
                    "bg-white text-brand border border-brand/40 hover:bg-brand/5 focus:ring-brand"

                "ghost" ->
                    "text-brand hover:bg-brand/5 focus:ring-brand"

                _ ->
                    "bg-brand-yellow text-brand hover:bg-brand hover:text-brand-yellow focus:ring-brand-yellow"
           )


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
