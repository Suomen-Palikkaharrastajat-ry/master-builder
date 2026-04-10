module MarkdownRenderer exposing (RenderContext, renderMarkdown)

{-| Markdown renderer for elm-pages content.
-}

import ContentMarkdown exposing (TocNode)
import Html exposing (Html)
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
    }


renderMarkdown : RenderContext -> String -> Html msg
renderMarkdown context markdown =
    case
        markdown
            |> Markdown.Parser.parse
            |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
            |> Result.andThen (Markdown.Renderer.render (Core.renderer context))
    of
        Ok rendered ->
            Html.article [ classes [ Tw.prose, Tw.prose_gray, Tw.max_w_none ] ] rendered

        Err err ->
            Html.pre [ classes [ Tw.text_simple TC.brandRed, Tw.type_caption, Tw.p s4, TwEx.bg_brand_red_10, Tw.rounded ] ] [ Html.text err ]
