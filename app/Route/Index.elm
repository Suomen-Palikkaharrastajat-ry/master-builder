module Route.Index exposing (ActionData, Data, Model, Msg, route)

{-| Route for the site index page (/).
-}

import BackendTask exposing (BackendTask)
import ContentDir
import ContentMarkdown exposing (TocNode)
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
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
    {}


type alias Data =
    { frontmatter : Frontmatter
    , body : String
    , childPages : List TocNode
    , pageDir : String
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                BackendTask.map2
                    (\pageData children ->
                        { frontmatter = pageData.frontmatter
                        , body = pageData.body
                        , childPages = children
                        , pageDir = pageData.pageDir
                        }
                    )
                    (ContentMarkdown.loadPage dir (dir ++ "/index.md"))
                    (ContentMarkdown.loadTocTree dir "")
            )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    let
        fm =
            app.data.frontmatter

        site =
            app.sharedData.config.site

        metadata =
            app.sharedData.config.metadata

        seoTitle =
            fm.title

        seoDescription =
            fm.description

        canonicalUrl =
            Metadata.pageCanonicalUrl site.url "/"

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
    { title = app.data.frontmatter.title
    , body = [ MarkdownRenderer.renderMarkdown { childPages = app.data.childPages, sectionSlug = Just "", pageDir = app.data.pageDir } app.data.body ]
    }
