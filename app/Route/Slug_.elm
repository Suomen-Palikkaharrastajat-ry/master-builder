module Route.Slug_ exposing (ActionData, Data, Model, Msg, route)

{-| Dynamic route for content pages (/:slug) — renders Markdown from the content/ directory.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import Component.Breadcrumb as Breadcrumb
import ContentDir
import ContentMarkdown exposing (TocNode)
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
import Html
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
    , childPages : List TocNode
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
                let
                    flatPages =
                        Glob.succeed (\slug -> { slug = slug })
                            |> Glob.match (Glob.literal (dir ++ "/"))
                            |> Glob.capture Glob.wildcard
                            |> Glob.match (Glob.literal ".md")
                            |> Glob.toBackendTask
                            |> BackendTask.map (List.filter (\p -> p.slug /= "index" && not (ContentMarkdown.isPartialSlug p.slug)))
                            |> BackendTask.andThen
                                (\params ->
                                    params
                                        |> List.map
                                            (\p ->
                                                ContentMarkdown.loadFrontmatter (dir ++ "/" ++ p.slug ++ ".md")
                                                    |> BackendTask.map (\fm -> ( p, fm.published ))
                                            )
                                        |> BackendTask.combine
                                        |> BackendTask.map (List.filterMap (\( p, pub ) -> if pub then Just p else Nothing))
                                )

                    sectionIndexes =
                        Glob.succeed (\section -> { slug = section })
                            |> Glob.match (Glob.literal (dir ++ "/"))
                            |> Glob.capture Glob.wildcard
                            |> Glob.match (Glob.literal "/index.md")
                            |> Glob.toBackendTask
                            |> BackendTask.andThen
                                (\params ->
                                    params
                                        |> List.map
                                            (\p ->
                                                ContentMarkdown.loadFrontmatter (dir ++ "/" ++ p.slug ++ "/index.md")
                                                    |> BackendTask.map (\fm -> ( p, fm.published ))
                                            )
                                        |> BackendTask.combine
                                        |> BackendTask.map (List.filterMap (\( p, pub ) -> if pub then Just p else Nothing))
                                )
                in
                BackendTask.map2 (++) flatPages sectionIndexes
            )


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                ContentMarkdown.loadPageOrSectionIndex dir routeParams.slug
                    |> BackendTask.andThen
                        (\pageData ->
                            ContentMarkdown.loadTocTree dir routeParams.slug
                                |> BackendTask.map
                                    (\tree ->
                                        { frontmatter = pageData.frontmatter
                                        , body = pageData.body
                                        , childPages = tree
                                        }
                                    )
                        )
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

        pageRobots =
            Maybe.withDefault metadata.robots fm.robots

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
        ++ (Head.metaName "robots" (Head.raw pageRobots) :: Metadata.maybeMetaName "author" pageAuthor)
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
        [ Breadcrumb.view
            [ { label = "Etusivu", href = Just "/" }
            , { label = app.data.frontmatter.title, href = Nothing }
            ]
        , MarkdownRenderer.renderMarkdown
            { childPages = app.data.childPages, sectionSlug = Just app.routeParams.slug }
            app.data.body
        ]
    }
