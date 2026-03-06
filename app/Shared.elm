module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.Attributes as Attr
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import UrlPath exposing (UrlPath)
import Route exposing (Route(..))
import SharedTemplate exposing (SharedTemplate)
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


type alias Data =
    ()


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
    BackendTask.succeed ()


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
view _ page _ _ pageView =
    case page.route of
        Just Admin ->
            -- Admin has its own full-page layout; render body directly
            { body = pageView.body, title = pageView.title }

        _ ->
            { body =
                [ Html.nav [ Attr.class "bg-white border-b border-gray-200" ]
                    [ Html.div [ Attr.class "max-w-5xl mx-auto px-6 py-4 flex items-center justify-between" ]
                        [ Html.a [ Attr.href "/", Attr.class "text-lg font-semibold text-gray-900 hover:text-gray-700 transition-colors" ]
                            [ Html.text "My Site" ]
                        , Html.a [ Attr.href "/admin", Attr.class "text-sm text-gray-500 hover:text-gray-900 transition-colors" ]
                            [ Html.text "Admin" ]
                        ]
                    ]
                , Html.main_ [ Attr.class "max-w-5xl mx-auto px-6 py-10 w-full" ] pageView.body
                ]
            , title = pageView.title
            }
