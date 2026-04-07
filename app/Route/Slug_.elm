module Route.Slug_ exposing (ActionData, Data, Model, Msg, route)

{-| Dynamic route for content pages (/:slug) — renders Markdown from the content/ directory.
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
import MarkdownRenderer
import Metadata
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
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
    let
        fm =
            app.data.frontmatter

        site =
            app.sharedData.config.site

        metadata =
            app.sharedData.config.metadata

        seoTitle =
            fm.title ++ " — " ++ site.title

        seoDescription =
            fm.description

        canonicalUrl =
            Metadata.pageCanonicalUrl site.url app.routeParams.slug

        pageAuthor =
            case fm.author of
                Just author ->
                    Just author

                Nothing ->
                    metadata.author

        baseSeo =
            { canonicalUrlOverride = Just canonicalUrl
            , siteName = site.title
            , image =
                Metadata.socialImage
                    { defaultImageAlt = metadata.defaultSocialImageAlt
                    , defaultImagePath = metadata.defaultSocialImage
                    , maybeImageAlt = fm.imageAlt
                    , maybeImagePath = fm.image
                    , siteUrl = site.url
                    }
            , description = seoDescription
            , locale = Nothing
            , title = seoTitle
            }
    in
    ((if metadata.twitterCard == "summary" then
        Seo.summary baseSeo

      else
        Seo.summaryLarge baseSeo
     )
        |> Seo.website
    )
        ++ Metadata.maybeMetaName "author" pageAuthor
        ++ [ Metadata.webPageStructuredData
                { title = seoTitle
                , description = seoDescription
                , url = canonicalUrl
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
