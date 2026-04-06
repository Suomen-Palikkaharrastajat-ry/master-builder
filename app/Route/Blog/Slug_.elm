module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

{-| Route for individual blog post pages at /blog/:slug.
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Component.Breadcrumb as Breadcrumb
import ContentDir
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
import Html
import Json.Decode as Decode
import LanguageTag.Language
import LanguageTag.Region
import MarkdownRenderer
import Metadata
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
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
                    |> Glob.match (Glob.literal (dir ++ "/blog/"))
                    |> Glob.capture Glob.wildcard
                    |> Glob.match (Glob.literal ".md")
                    |> Glob.toBackendTask
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
                    (dir ++ "/blog/" ++ routeParams.slug ++ ".md")
                    |> BackendTask.allowFatal
            )


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    let
        fm =
            app.data.frontmatter

        site =
            app.sharedData.config.site

        pageTitle =
            fm.title ++ " — " ++ site.title
    in
    (Seo.summaryLarge
        { canonicalUrlOverride = Nothing
        , siteName = site.title
        , image = Metadata.socialImage site.url fm.title fm.image
        , description = fm.description
        , locale = Just ( LanguageTag.Language.fi, LanguageTag.Region.fi )
        , title = pageTitle
        }
        |> Seo.website
    )
        ++ [ Metadata.webPageStructuredData
                { title = pageTitle
                , description = fm.description
                , url = Metadata.absoluteUrl site.url ("blog/" ++ app.routeParams.slug)
                }
           ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.frontmatter.title ++ " — " ++ app.sharedData.config.site.title
    , body =
        [ Breadcrumb.viewBack { label = "Etusivulle", href = "/" }
        , MarkdownRenderer.renderMarkdown app.data.body
        ]
    }
