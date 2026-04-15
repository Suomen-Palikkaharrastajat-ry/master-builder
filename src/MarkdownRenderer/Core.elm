module MarkdownRenderer.Core exposing (renderer)

{-| Core markdown block renderer configuration.
-}

import ContentMarkdown exposing (TocNode)
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Renderer
import MarkdownRenderer.Helpers as Helpers
import MarkdownRenderer.HtmlTags as HtmlTags
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s0_dot_5, s1, s1_dot_5, s2, s3, s4, s6, s8)
import TailwindExtra as TwEx
import TailwindTokens as TC


renderer : { childPages : List TocNode, sectionSlug : Maybe String } -> Markdown.Renderer.Renderer (Html msg)
renderer context =
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
    , html = HtmlTags.htmlRenderer context
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
        ([ Attr.href link.destination
         , classes
            [ Tw.text_simple TC.brand
            , Tw.type_body
            , Tw.underline
            , Tw.underline_offset_2
            , Bp.hover [ Tw.opacity_70 ]
            , Bp.withVariant "motion-safe" [ Tw.transition_opacity ]
            ]
         ]
            ++ Helpers.externalLinkAttrs link.destination
        )
        children


viewImage : { alt : String, src : String, title : Maybe String } -> Html msg
viewImage img =
    let
        ( rawClasses, altText ) =
            Helpers.splitClassPrefix img.alt

        figAttrs =
            case rawClasses of
                Just classStr ->
                    [ Attr.class classStr ]

                Nothing ->
                    [ classes [ Tw.my s8 ] ]
    in
    Html.figure figAttrs
        [ Html.img
            [ Attr.src (Helpers.normalizeSrc img.src)
            , Attr.alt altText
            ]
            []
        , case img.title of
            Just title ->
                Html.figcaption
                    [ classes [ Tw.mt s2, Tw.text_center, Tw.type_caption, Tw.text_simple TC.textMuted ] ]
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
    let
        codeBody =
            case language of
                Just "html" ->
                    Helpers.decodeHtmlEntities body

                _ ->
                    body
    in
    Html.div [ classes [ Tw.my s6, Tw.rounded_lg, Tw.overflow_hidden ] ]
        [ case language of
            Just lang ->
                Html.div [ classes [ Tw.px s4, Tw.py s1_dot_5, Tw.bg_simple TC.brand, TwEx.text_white_70, Tw.type_mono ] ]
                    [ Html.text lang ]

            Nothing ->
                Html.text ""
        , Html.pre
            [ classes [ Tw.bg_simple TC.brand, TwEx.text_white_90, Tw.p s4, Tw.overflow_x_auto, Tw.type_mono, Tw.leading_relaxed ] ]
            [ Html.code [] [ Html.text codeBody ] ]
        ]
