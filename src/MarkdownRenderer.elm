module MarkdownRenderer exposing (HeadingItem, RenderContext, renderMarkdown)

{-| Markdown renderer for elm-pages content.
-}

import ContentMarkdown exposing (TocNode)
import Html exposing (Html)
import Markdown.Block as Block
import Markdown.Parser
import Markdown.Renderer
import MarkdownRenderer.Core as Core
import Tailwind as Tw exposing (classes)
import Tailwind.Theme exposing (s4)
import TailwindExtra as TwEx
import TailwindTokens as TC


type alias RenderContext =
    { childPages : List TocNode
    , sectionSlug : Maybe String
    , pageDir : String
    , isIndex : Bool
    }


type alias HeadingItem =
    { level : Int
    , text : String
    , id : String
    }


headingSlug : String -> String
headingSlug text =
    text
        |> String.toLower
        |> String.map (\c -> if Char.isAlphaNum c then c else '-')
        |> String.split "-"
        |> List.filter (not << String.isEmpty)
        |> String.join "-"


extractHeadings : String -> List HeadingItem
extractHeadings markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.withDefault []
        |> List.filterMap
            (\block ->
                case block of
                    Block.Heading level inlines ->
                        let
                            text =
                                Block.extractInlineText inlines
                        in
                        Just { level = Block.headingLevelToInt level, text = text, id = headingSlug text }

                    _ ->
                        Nothing
            )


renderMarkdown : RenderContext -> String -> Html msg
renderMarkdown context markdown =
    let
        internalCtx =
            { childPages = context.childPages
            , sectionSlug = context.sectionSlug
            , pageDir = context.pageDir
            , isIndex = context.isIndex
            , headings = extractHeadings markdown
            }
    in
    case
        markdown
            |> Markdown.Parser.parse
            |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
            |> Result.andThen (Markdown.Renderer.render (Core.renderer internalCtx))
    of
        Ok rendered ->
            Html.article [ classes [ Tw.prose, Tw.prose_gray, Tw.max_w_none ] ] rendered

        Err err ->
            Html.pre [ classes [ Tw.text_simple TC.brandRed, Tw.type_caption, Tw.p s4, TwEx.bg_brand_red_10, Tw.rounded ] ] [ Html.text err ]
