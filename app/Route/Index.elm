module Route.Index exposing (ActionData, Data, Model, Msg, route)

{-| Route for the site index page (/).
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import ContentDir
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
import Json.Decode as Decode
import LanguageTag.Language
import LanguageTag.Region
import MarkdownRenderer
import Pages.Url
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
                File.bodyWithFrontmatter
                    (\body ->
                        Frontmatter.decoder
                            |> Decode.map (\fm -> { frontmatter = fm, body = body })
                    )
                    (dir ++ "/index.md")
                    |> BackendTask.allowFatal
            )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    let
        fm =
            app.data.frontmatter
    in
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = app.sharedData.config.site.title
        , image =
            { url =
                fm.image
                    |> Maybe.map Pages.Url.external
                    |> Maybe.withDefault (Pages.Url.external "")
            , alt = fm.title
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = fm.description
        , locale = Just ( LanguageTag.Language.fi, LanguageTag.Region.fi )
        , title = fm.title
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.frontmatter.title
    , body = [ MarkdownRenderer.renderMarkdown app.data.body ]
    }
