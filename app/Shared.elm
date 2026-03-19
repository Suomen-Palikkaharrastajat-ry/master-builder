module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import ContentDir
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Frontmatter
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route(..))
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = SharedMsg SharedMsg
    | MenuClicked


type alias NavItem =
    { title : String
    , slug : String
    }


type alias Data =
    List NavItem


type SharedMsg
    = NoOp


type alias Model =
    { showMenu : Bool
    }


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags maybePagePath =
    ( { showMenu = False }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg globalMsg ->
            ( model, Effect.none )

        MenuClicked ->
            ( { model | showMenu = not model.showMenu }, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                Glob.succeed identity
                    |> Glob.match (Glob.literal (dir ++ "/"))
                    |> Glob.capture Glob.wildcard
                    |> Glob.match (Glob.literal ".md")
                    |> Glob.toBackendTask
                    |> BackendTask.andThen
                        (\slugs ->
                            slugs
                                |> List.filter (\s -> s /= "index")
                                |> List.map
                                    (\slug ->
                                        File.bodyWithFrontmatter
                                            (\_ -> Frontmatter.decoder)
                                            (dir ++ "/" ++ slug ++ ".md")
                                            |> BackendTask.allowFatal
                                    )
                                |> BackendTask.combine
                        )
            )
        |> BackendTask.map
            (List.filter (\fm -> fm.nav)
                >> List.map (\fm -> { title = fm.title, slug = fm.slug })
            )


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view navItems page model toMsg pageView =
    case page.route of
        Just Admin ->
            { body = pageView.body, title = pageView.title }

        _ ->
            { body =
                [ Html.a
                    [ Attr.href "#main-content"
                    , Attr.class "sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:px-4 focus:py-2 focus:bg-brand-yellow focus:text-brand focus:font-semibold focus:rounded focus:ring-2 focus:ring-brand"
                    ]
                    [ Html.text "Siirry pääsisältöön" ]
                , Html.nav [ Attr.class "bg-brand shadow-sm" ]
                    [ Html.div [ Attr.class "max-w-5xl mx-auto px-6 py-3 flex items-center" ]
                        [ Html.a [ Attr.href "/", Attr.class "shrink-0" ]
                            [ Html.img
                                [ Attr.src "https://logo.palikkaharrastajat.fi/logo/square/svg/square-smile.svg"
                                , Attr.alt "Suomen Palikkaharrastajat ry"
                                , Attr.class "h-14 lg:hidden"
                                ]
                                []
                            , Html.img
                                [ Attr.src "https://logo.palikkaharrastajat.fi/logo/horizontal/svg/horizontal-full-dark.svg"
                                , Attr.alt "Suomen Palikkaharrastajat ry"
                                , Attr.class "h-14 max-lg:hidden"
                                ]
                                []
                            ]
                        , Html.div [ Attr.class "flex-1" ] []
                        , Html.div [ Attr.class "max-lg:hidden flex items-center gap-6" ]
                            (List.map navLink navItems)
                        , Html.button
                            [ Attr.class "lg:hidden text-white/80 hover:text-white transition-colors p-1 -mr-1 cursor-pointer focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-brand rounded"
                            , Attr.attribute "aria-label" "Avaa valikko"
                            , Attr.attribute "aria-expanded"
                                (if model.showMenu then
                                    "true"

                                 else
                                    "false"
                                )
                            , Events.onClick (toMsg MenuClicked)
                            ]
                            [ if model.showMenu then
                                Html.span [ Attr.class "text-2xl leading-none select-none" ] [ Html.text "✕" ]

                              else
                                Html.span [ Attr.class "text-2xl leading-none select-none" ] [ Html.text "☰" ]
                            ]
                        ]
                    , if model.showMenu then
                        Html.div [ Attr.class "lg:hidden border-t border-white/10 px-6 py-3 flex flex-col items-end gap-1" ]
                            (List.map (navLinkMobile (toMsg MenuClicked)) navItems)

                      else
                        Html.text ""
                    ]
                , Html.main_ [ Attr.id "main-content", Attr.class "max-w-5xl mx-auto px-6 py-10 w-full" ] pageView.body
                ]
            , title = pageView.title
            }


navLink : NavItem -> Html msg
navLink item =
    Html.a
        [ Attr.href ("/" ++ item.slug)
        , Attr.class "text-sm text-white/80 hover:text-white transition-colors focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-brand rounded"
        ]
        [ Html.text item.title ]


navLinkMobile : msg -> NavItem -> Html msg
navLinkMobile onClose item =
    Html.a
        [ Attr.href ("/" ++ item.slug)
        , Attr.class "block py-2 text-sm text-white/80 hover:text-white transition-colors focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-brand rounded"
        , Events.onClick onClose
        ]
        [ Html.text item.title ]
