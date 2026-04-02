module Route.Slug_ exposing (ActionData, Data, Model, Msg, route)

{-| Dynamic route for content pages (/:slug) — renders Markdown from the content/ directory.
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import ContentDir
import FatalError exposing (FatalError)
import FeatherIcons
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Json.Decode as Decode
import MarkdownRenderer
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s1, s6)
import TailwindTokens as TC
import UrlPath
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias Data =
    { frontmatter : Frontmatter
    , body : String
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                Glob.succeed (\slug -> { slug = slug })
                    |> Glob.match (Glob.literal (dir ++ "/"))
                    |> Glob.capture Glob.wildcard
                    |> Glob.match (Glob.literal ".md")
                    |> Glob.toBackendTask
                    |> BackendTask.map (List.filter (\p -> p.slug /= "index"))
            )


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                File.bodyWithFrontmatter
                    (\body ->
                        Frontmatter.decoder
                            |> Decode.map (\fm -> { frontmatter = fm, body = body })
                    )
                    (dir ++ "/" ++ routeParams.slug ++ ".md")
                    |> BackendTask.allowFatal
            )


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "My Site"
        , image =
            { url = Pages.Url.external ""
            , alt = ""
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = app.data.frontmatter.description
        , locale = Nothing
        , title = app.data.frontmatter.title ++ " — Suomen Palikkaharrastajat ry"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.frontmatter.title ++ " — Suomen Palikkaharrastajat ry"
    , body =
        [ Html.a
            [ Attr.href "/"
            , classes
                [ Tw.inline_flex
                , Tw.items_center
                , Tw.gap s1
                , Tw.type_caption
                , Tw.text_simple TC.textMuted
                , Bp.hover [ Tw.text_simple TC.textPrimary ]
                , Tw.mb s6
                , Bp.withVariant "motion-safe" [ Tw.transition_colors ]
                ]
            ]
            [ FeatherIcons.arrowLeft
                |> FeatherIcons.withSize 14
                |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true" ]
            , Html.text "Etusivulle"
            ]
        , MarkdownRenderer.renderMarkdown app.data.body
        ]
    }
