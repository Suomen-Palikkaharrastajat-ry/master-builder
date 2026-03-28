module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Browser.Events
import Component.MobileDrawer as MobileDrawer
import ContentDir
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import FeatherIcons
import Frontmatter
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events
import Json.Decode
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Ports
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


type alias NavItem =
    { title : String
    , slug : String
    }


type alias Data =
    List NavItem


type SharedMsg
    = NoOp
    | ToggleMenu
    | CloseMenu


type Msg
    = SharedMsg SharedMsg


type alias Model =
    { menuOpen : Bool
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
init _ _ =
    ( { menuOpen = False }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg ToggleMenu ->
            if model.menuOpen then
                ( { model | menuOpen = False }, Effect.none )

            else
                ( { model | menuOpen = True }, Effect.fromCmd (Ports.focusMobileNav ()) )

        SharedMsg CloseMenu ->
            ( { model | menuOpen = False }, Effect.none )

        SharedMsg _ ->
            ( model, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ model =
    if model.menuOpen then
        Browser.Events.onKeyDown
            (Json.Decode.field "key" Json.Decode.string
                |> Json.Decode.andThen
                    (\key ->
                        if key == "Escape" then
                            Json.Decode.succeed (SharedMsg CloseMenu)

                        else
                            Json.Decode.fail "not escape"
                    )
            )

    else
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
        _ ->
            { body =
                [ Html.a
                    [ Attr.href "#main-content"
                    , Attr.class "sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:px-4 focus:py-2 focus:bg-brand-yellow focus:text-brand focus:type-body-small focus:rounded focus-visible:ring-2 focus-visible:ring-brand"
                    ]
                    [ Html.text "Siirry pääsisältöön" ]
                , Html.div [ Attr.class "min-h-screen flex flex-col" ]
                    [ viewNavbar model (toMsg << SharedMsg) navItems
                    , Html.main_ [ Attr.id "main-content", Attr.class "flex-1 max-w-5xl mx-auto px-6 py-10 w-full" ] pageView.body
                    , viewFooter
                    , MobileDrawer.viewOverlay { isOpen = model.menuOpen, onClose = toMsg (SharedMsg CloseMenu), breakpoint = MobileDrawer.Lg }
                    , viewMobileDrawer page.path model (toMsg << SharedMsg) navItems
                    ]
                ]
            , title = pageView.title
            }


viewNavbar : Model -> (SharedMsg -> msg) -> List NavItem -> Html msg
viewNavbar model toMsg navItems =
    Html.nav [ Attr.class "bg-brand shadow-sm sticky top-0 z-50" ]
        [ Html.div [ Attr.class "max-w-5xl mx-auto px-6 py-3 flex items-center" ]
            [ Html.a
                [ Attr.href "/"
                , Attr.class "shrink-0"
                , Html.Events.onClick (toMsg CloseMenu)
                ]
                [ Html.img
                    [ Attr.src "https://logo.palikkaharrastajat.fi/logo/horizontal/svg/horizontal-full-dark.svg"
                    , Attr.alt "Suomen Palikkaharrastajat ry"
                    , Attr.class "h-14"
                    ]
                    []
                ]
            , Html.div [ Attr.class "flex-1" ] []
            , Html.div [ Attr.class "max-lg:hidden flex items-center gap-6" ]
                (List.map navLink navItems)
            , Html.button
                [ Attr.class "lg:hidden text-white/80 hover:text-white motion-safe:transition-colors p-1 -mr-1 cursor-pointer focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-brand rounded"
                , Attr.attribute "aria-label"
                    (if model.menuOpen then
                        "Sulje valikko"

                     else
                        "Avaa valikko"
                    )
                , Attr.attribute "aria-expanded"
                    (if model.menuOpen then
                        "true"

                     else
                        "false"
                    )
                , Attr.attribute "aria-controls" "mobile-nav"
                , Html.Events.onClick (toMsg ToggleMenu)
                ]
                [ if model.menuOpen then
                    FeatherIcons.x |> FeatherIcons.withSize 24 |> FeatherIcons.toHtml []

                  else
                    FeatherIcons.menu |> FeatherIcons.withSize 24 |> FeatherIcons.toHtml []
                ]
            ]
        ]


navLink : NavItem -> Html msg
navLink item =
    Html.a
        [ Attr.href ("/" ++ item.slug)
        , Attr.class "type-caption text-white/80 hover:text-white motion-safe:transition-colors focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-brand rounded"
        ]
        [ Html.text item.title ]


viewMobileDrawer : UrlPath -> Model -> (SharedMsg -> msg) -> List NavItem -> Html msg
viewMobileDrawer currentPath model toMsg navItems =
    let
        isActive slug =
            UrlPath.toRelative currentPath == slug

        close =
            toMsg CloseMenu
    in
    MobileDrawer.view
        { isOpen = model.menuOpen
        , id = "mobile-nav"
        , onClose = close
        , breakpoint = MobileDrawer.Lg
        , content =
            [ Html.nav [ Attr.class "p-4" ]
                [ Html.ul [ Attr.class "flex flex-col gap-1 list-none m-0 p-0" ]
                    (List.map
                        (\item ->
                            MobileDrawer.viewNavLink
                                { href = "/" ++ item.slug
                                , label = item.title
                                , isActive = isActive item.slug
                                , onClose = close
                                }
                        )
                        navItems
                    )
                ]
            ]
        }


viewFooter : Html msg
viewFooter =
    Html.footer
        [ Attr.class "bg-brand text-white mt-16 py-12 px-4" ]
        [ Html.div
            [ Attr.class "max-w-5xl mx-auto" ]
            [ Html.div
                [ Attr.class "grid grid-cols-1 sm:grid-cols-[auto_1fr] gap-8 sm:items-end" ]
                [ -- Col 1: service links + logo
                  Html.div [ Attr.class "flex items-start gap-4" ]
                    [ Html.img
                        [ Attr.src "https://logo.palikkaharrastajat.fi/logo/square/svg/square-smile-full-dark.svg"
                        , Attr.alt ""
                        , Attr.attribute "aria-hidden" "true"
                        , Attr.class "h-35 w-35 flex-shrink-0"
                        ]
                        []
                    , Html.div [ Attr.class "space-y-3" ]
                        [ Html.p [ Attr.class "text-xs font-semibold text-white/50 uppercase tracking-wider" ]
                            [ Html.text "Palikkaharrastajat" ]
                        , Html.div [ Attr.class "flex gap-4" ]
                            [ Html.ul [ Attr.class "space-y-2 list-none m-0 p-0" ]
                                [ Html.li []
                                    [ Html.a
                                        [ Attr.href "https://forum.palikkaharrastajat.fi"
                                        , Attr.class "text-sm text-white/80 hover:text-white underline transition-colors"
                                        ]
                                        [ Html.text "Jäsenfoorumi" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://kortti.palikkaharrastajat.fi"
                                        , Attr.class "text-sm text-white/80 hover:text-white underline transition-colors"
                                        ]
                                        [ Html.text "Jäsenkortti" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://maksut.palikkaharrastajat.fi"
                                        , Attr.class "text-sm text-white/80 hover:text-white underline transition-colors"
                                        ]
                                        [ Html.text "Jäsenmaksu" ]
                                    ]
                                ]
                            , Html.ul [ Attr.class "space-y-2 list-none m-0 p-0" ]
                                [ Html.li []
                                    [ Html.a
                                        [ Attr.href "https://kalenteri.palikkaharrastajat.fi"
                                        , Attr.class "text-sm text-white/80 hover:text-white underline transition-colors"
                                        ]
                                        [ Html.text "Palikkakalenteri" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://linkit.palikkaharrastajat.fi"
                                        , Attr.class "text-sm text-white/80 hover:text-white underline transition-colors"
                                        ]
                                        [ Html.text "Palikkalinkit" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , -- Col 2: org name & legal
                  Html.div [ Attr.class "space-y-1 sm:text-right" ]
                    [ Html.div [ Attr.class "space-y-1 text-xs text-white/50" ]
                        [ Html.p [] [ Html.text "© 2026 Suomen Palikkaharrastajat ry" ]
                        , Html.p [] [ Html.text "LEGO® on LEGO Groupin rekisteröity tavaramerkki" ]
                        ]
                    ]
                ]
            ]
        ]
