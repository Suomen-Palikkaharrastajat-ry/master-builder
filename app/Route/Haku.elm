module Route.Haku exposing (ActionData, Data, Model, Msg(..), route)

{-| Search results page at /haku.
-}

import BackendTask exposing (BackendTask)
import Dict
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Metadata
import PagesMsg exposing (PagesMsg)
import Ports
import RouteBuilder exposing (App, StatefulRoute)
import Shared
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s0, s1, s2, s3, s4, s6, s8)
import TailwindExtra as TwEx
import TailwindTokens as TC
import UrlPath exposing (UrlPath)
import View exposing (View)


type alias Model =
    { query : String
    , status : SearchStatus
    , results : List Ports.SearchResult
    }


type SearchStatus
    = Idle
    | Searching
    | Ready


type Msg
    = SearchResultsReceived (List Ports.SearchResult)


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = BackendTask.succeed {}
        }
        |> RouteBuilder.buildWithLocalState
            { init = init
            , update = update
            , subscriptions = subscriptions
            , view = view
            }


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init app _ =
    let
        query =
            queryFromApp app
    in
    if String.isEmpty query then
        ( { query = "", status = Idle, results = [] }
        , Effect.none
        )

    else
        ( { query = query, status = Searching, results = [] }
        , Effect.fromCmd (Ports.performSearch query)
        )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update _ _ msg model =
    case msg of
        SearchResultsReceived results ->
            ( { model | results = results, status = Ready }, Effect.none )


subscriptions :
    RouteParams
    -> UrlPath
    -> Shared.Model
    -> Model
    -> Sub Msg
subscriptions _ _ _ _ =
    Ports.searchResults SearchResultsReceived


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    let
        site =
            app.sharedData.config.site

        metadata =
            app.sharedData.config.metadata

        seoTitle =
            "Haku — " ++ site.title

        seoDescription =
            "Hae sivuston sisällöistä."

        canonicalUrl =
            Metadata.pageCanonicalUrl site.url "haku"

        baseSeo =
            { canonicalUrlOverride = Just canonicalUrl
            , siteName = site.title
            , image =
                Metadata.socialImage
                    { defaultImageAlt = metadata.defaultSocialImageAlt
                    , defaultImagePath = metadata.defaultSocialImage
                    , maybeImageAlt = Nothing
                    , maybeImagePath = Nothing
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
        ++ [ Head.metaName "robots" (Head.raw "noindex, follow")
           ]
        ++ Metadata.maybeMetaName "author" metadata.author
        ++ [ Metadata.webPageStructuredData
                { title = seoTitle
                , description = seoDescription
                , url = canonicalUrl
                }
           ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ model =
    { title = "Haku — " ++ app.sharedData.config.site.title
    , body =
        [ Html.section [ classes [ Tw.flex, Tw.flex_col, Tw.gap s8 ] ]
            [ Html.div [ classes [ Tw.flex, Tw.flex_col, Tw.gap s3 ] ]
                [ Html.h1 [ classes [ Tw.type_h1, Tw.text_simple TC.textPrimary ] ] [ Html.text "Haku" ]
                , Html.p [ classes [ Tw.type_body, Tw.text_simple TC.textMuted ] ] [ Html.text "Hae sivuston sivuja otsikon, kuvauksen ja sisällön perusteella." ]
                ]
            , viewSearchForm model.query
            , viewResultBlock model
            ]
        ]
    }


queryFromApp : App Data ActionData RouteParams -> String
queryFromApp app =
    app.url
        |> Maybe.andThen (\url -> Dict.get "q" url.query |> Maybe.andThen List.head)
        |> Maybe.map String.trim
        |> Maybe.withDefault ""


viewSearchForm : String -> Html msg
viewSearchForm query =
    Html.form
        [ Attr.action "/haku"
        , Attr.method "GET"
        , classes
            [ Tw.flex
            , Tw.flex_col
            , Bp.sm [ Tw.flex_row, Tw.items_center ]
            , Tw.gap s2
            , Tw.rounded_lg
            , Tw.border
            , Tw.border_simple TC.borderDefault
            , Tw.bg_simple TC.bgSubtle
            , Tw.p s2
            ]
        ]
        [ Html.label [ Attr.for "search-page-input", classes [ Tw.sr_only ] ] [ Html.text "Hae sivustolta" ]
        , Html.input
            [ Attr.id "search-page-input"
            , Attr.name "q"
            , Attr.type_ "search"
            , Attr.placeholder "Hae esimerkiksi jasenyys, saannot tai tapahtuma"
            , Attr.value query
            , classes
                [ Tw.w_full
                , Tw.rounded_md
                , Tw.border
                , Tw.border_simple TC.borderDefault
                , Tw.bg_simple TC.bgPage
                , Tw.px s3
                , Tw.py s2
                , Tw.type_body
                , Tw.text_simple TC.textPrimary
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                ]
            ]
            []
        , Html.button
            [ Attr.type_ "submit"
            , classes
                [ Tw.rounded_md
                , Tw.bg_simple TC.brand
                , Tw.px s4
                , Tw.py s2
                , Tw.type_body_small
                , Tw.text_simple TC.textOnDark
                , Tw.cursor_pointer
                , Bp.hover [ Tw.bg_simple TC.brandYellow, Tw.text_simple TC.brand ]
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                ]
            ]
            [ Html.text "Hae" ]
        ]


viewResultBlock : Model -> Html msg
viewResultBlock model =
    if String.isEmpty model.query then
        Html.p [ classes [ Tw.type_body, Tw.text_simple TC.textMuted ] ]
            [ Html.text "Anna hakusana, niin naytamme siihen sopivat sivut." ]

    else
        case model.status of
            Searching ->
                Html.p [ classes [ Tw.type_body, Tw.text_simple TC.textMuted ] ]
                    [ Html.text ("Haetaan tuloksia hakusanalle \"" ++ model.query ++ "\"...") ]

            Idle ->
                Html.text ""

            Ready ->
                if List.isEmpty model.results then
                    Html.p [ classes [ Tw.type_body, Tw.text_simple TC.textMuted ] ]
                        [ Html.text ("Ei hakutuloksia hakusanalle \"" ++ model.query ++ "\".") ]

                else
                    Html.div [ classes [ Tw.flex, Tw.flex_col, Tw.gap s3 ] ]
                        [ Html.p [ classes [ Tw.type_body_small, Tw.text_simple TC.textMuted ] ]
                            [ Html.text (String.fromInt (List.length model.results) ++ " hakutulosta") ]
                        , Html.ul [ classes [ Tw.flex, Tw.flex_col, Tw.gap s3, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                            (List.map viewResultItem model.results)
                        ]


viewResultItem : Ports.SearchResult -> Html msg
viewResultItem result =
    Html.li
        [ classes
            [ Tw.rounded_lg
            , Tw.border
            , Tw.border_simple TC.borderDefault
            , Tw.bg_simple TC.bgPage
            , Tw.p s4
            , Tw.transition_colors
            , Bp.hover [ Tw.bg_simple TC.bgSubtle ]
            ]
        ]
        [ Html.h2 [ classes [ Tw.type_h4, Tw.m s0 ] ]
            [ Html.a
                [ Attr.href result.path
                , classes
                    [ Tw.text_simple TC.brand
                    , Bp.hover [ Tw.text_simple TC.brandYellow ]
                    , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand, Tw.rounded_sm ]
                    ]
                ]
                [ Html.text result.title ]
            ]
        , Html.p [ classes [ Tw.mt s2, Tw.type_body, Tw.text_simple TC.textPrimary ] ]
            [ Html.text result.description ]
        , Html.p [ classes [ Tw.mt s1, Tw.type_caption, Tw.text_simple TC.textSubtle ] ]
            [ Html.text result.path ]
        ]
