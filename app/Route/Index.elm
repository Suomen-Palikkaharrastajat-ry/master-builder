module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
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
    { pages : List Frontmatter }


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
    Glob.succeed identity
        |> Glob.match (Glob.literal "content/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (\slugs ->
                slugs
                    |> List.map
                        (\slug ->
                            File.bodyWithFrontmatter
                                (\_ -> Frontmatter.decoder)
                                ("content/" ++ slug ++ ".md")
                                |> BackendTask.allowFatal
                        )
                    |> BackendTask.combine
            )
        |> BackendTask.map
            (List.filter .published
                >> List.sortBy .title
                >> (\pages_ -> { pages = pages_ })
            )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
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
        , description = "Welcome to My Site"
        , locale = Nothing
        , title = "Home"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = "Home"
    , body =
        [ Html.h1 [ Attr.class "text-3xl font-bold text-gray-900 mb-2" ]
            [ Html.text "Pages" ]
        , Html.p [ Attr.class "text-gray-500 mb-8" ]
            [ Html.text "All published content" ]
        , Html.ul [ Attr.class "divide-y divide-gray-100 border border-gray-200 rounded-xl overflow-hidden bg-white shadow-sm" ]
            (List.map
                (\page ->
                    Html.li []
                        [ Html.a
                            [ Attr.href ("/" ++ page.slug)
                            , Attr.class "flex flex-col px-5 py-4 hover:bg-gray-50 transition-colors"
                            ]
                            [ Html.span [ Attr.class "font-medium text-gray-900" ]
                                [ Html.text page.title ]
                            , if String.isEmpty page.description then
                                Html.text ""

                              else
                                Html.span [ Attr.class "text-sm text-gray-500 mt-0.5" ]
                                    [ Html.text page.description ]
                            ]
                        ]
                )
                app.data.pages
            )
        ]
    }
