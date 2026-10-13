module ErrorPage exposing (ErrorPage(..), Model, Msg, head, init, internalError, notFound, statusCode, update, view)

{-| elm-pages error page handler (404, 500, etc.).
-}

import Effect exposing (Effect)
import Head
import Html exposing (Html)
import Html.Attributes as Attr
import Lang
import UiStrings
import View exposing (View)


type Msg
    = Increment


type alias Model =
    { count : Int
    }


init : ErrorPage -> ( Model, Effect Msg )
init errorPage =
    ( { count = 0 }
    , Effect.none
    )


update : ErrorPage -> Msg -> Model -> ( Model, Effect Msg )
update errorPage msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }, Effect.none )


head : ErrorPage -> List Head.Tag
head errorPage =
    []


type ErrorPage
    = NotFound
    | InternalError String


notFound : ErrorPage
notFound =
    NotFound


internalError : String -> ErrorPage
internalError =
    InternalError


{-| elm-pages gives the error page no access to the site configuration, so it
cannot know the site's language. It says its piece in every supported one, each
marked with its language.
-}
view : ErrorPage -> Model -> View Msg
view error _ =
    let
        inLanguage lang =
            let
                strings =
                    UiStrings.forLang lang
            in
            Html.p [ Attr.lang (Lang.toString lang) ]
                [ Html.text <|
                    case error of
                        NotFound ->
                            strings.pageNotFound

                        InternalError detail ->
                            strings.unexpectedError ++ "\n" ++ detail
                ]

        title lang =
            case error of
                NotFound ->
                    (UiStrings.forLang lang).pageNotFoundTitle

                InternalError _ ->
                    (UiStrings.forLang lang).unexpectedErrorTitle
    in
    { body = [ Html.div [] (List.map inLanguage Lang.all) ]
    , title = String.join " / " (List.map title Lang.all)
    }


statusCode : ErrorPage -> number
statusCode error =
    case error of
        NotFound ->
            404

        InternalError _ ->
            500
