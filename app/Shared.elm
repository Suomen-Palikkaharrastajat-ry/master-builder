module Shared exposing (Data, Model, Msg(..), SharedMsg(..), strings, template)

{-| Shared layout shell: navbar, footer, and mobile drawer.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import Component.Layout as Layout
import Config exposing (Config)
import ContentDir
import ContentMarkdown
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import FeatherIcons
import Frontmatter exposing (NavVisibility(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Ports
import Route exposing (Route(..))
import SharedTemplate exposing (SharedTemplate)
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s0, s1, s10, s14, s2, s3, s4, s6, s8, white)
import TailwindExtra as TwEx
import TailwindTokens as TC
import UiStrings exposing (UiStrings)
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
    , path : String
    , order : Int
    , mobileOnly : Bool
    }


type alias Data =
    { navItems : List NavItem
    , config : Config
    }


type SharedMsg
    = NoOp
    | ToggleMenu
    | CloseMenu
    | ScrollY Float
    | ScrollToTop


type Msg
    = SharedMsg SharedMsg


type alias Model =
    { menuOpen : Bool
    , scrollY : Float
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
    ( { menuOpen = False, scrollY = 0 }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg ToggleMenu ->
            if model.menuOpen then
                ( { model | menuOpen = False }, Effect.fromCmd (Layout.onMenuClosed (SharedMsg NoOp)) )

            else
                ( { model | menuOpen = True }, Effect.fromCmd (Layout.onMenuOpened (SharedMsg NoOp)) )

        SharedMsg CloseMenu ->
            if model.menuOpen then
                ( { model | menuOpen = False }, Effect.fromCmd (Layout.onMenuClosed (SharedMsg NoOp)) )

            else
                ( model, Effect.none )

        SharedMsg (ScrollY y) ->
            ( { model | scrollY = y }, Effect.none )

        SharedMsg ScrollToTop ->
            ( model, Effect.fromCmd (Ports.scrollToTop ()) )

        SharedMsg _ ->
            ( model, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ model =
    Sub.batch
        [ Layout.subscriptions { isOpen = model.menuOpen, onClose = SharedMsg CloseMenu }
        , Ports.onScroll (SharedMsg << ScrollY)
        ]


navItemsTask : BackendTask FatalError (List NavItem)
navItemsTask =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                let
                    flatFrontmatters =
                        Glob.succeed identity
                            |> Glob.match (Glob.literal (dir ++ "/"))
                            |> Glob.capture Glob.wildcard
                            |> Glob.match (Glob.literal ".md")
                            |> Glob.toBackendTask
                            |> BackendTask.andThen
                                (\slugs ->
                                    slugs
                                        |> List.filter (\slug -> not (ContentMarkdown.isPartialSlug slug))
                                        |> List.map
                                            (\slug ->
                                                ContentMarkdown.loadFrontmatter (dir ++ "/" ++ slug ++ ".md")
                                                    |> BackendTask.map
                                                        (\fm ->
                                                            { frontmatter = fm
                                                            , path =
                                                                if slug == "index" then
                                                                    "/"

                                                                else
                                                                    "/" ++ slug
                                                            }
                                                        )
                                            )
                                        |> BackendTask.combine
                                )

                    sectionFrontmatters =
                        Glob.succeed identity
                            |> Glob.match (Glob.literal (dir ++ "/"))
                            |> Glob.capture Glob.wildcard
                            |> Glob.match (Glob.literal "/index.md")
                            |> Glob.toBackendTask
                            |> BackendTask.andThen
                                (\sections ->
                                    sections
                                        |> List.map
                                            (\section ->
                                                ContentMarkdown.loadFrontmatter (dir ++ "/" ++ section ++ "/index.md")
                                                    |> BackendTask.map
                                                        (\fm ->
                                                            { frontmatter = fm
                                                            , path = "/" ++ section
                                                            }
                                                        )
                                            )
                                        |> BackendTask.combine
                                )
                in
                BackendTask.map2 (++) flatFrontmatters sectionFrontmatters
            )
        |> BackendTask.map
            (List.filter (\item -> item.frontmatter.nav /= NavHidden && item.frontmatter.published)
                >> List.map
                    (\item ->
                        let
                            fm =
                                item.frontmatter
                        in
                        { title = Maybe.withDefault fm.title fm.navTitle
                        , path = item.path
                        , order = fm.order
                        , mobileOnly = fm.nav == NavMobileOnly
                        }
                    )
                >> List.sortBy .order
            )


data : BackendTask FatalError Data
data =
    BackendTask.map2 Data navItemsTask Config.task


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
view sharedData page model toMsg pageView =
    let
        config =
            sharedData.config

        uiStrings =
            strings sharedData

        isCompact =
            config.navbar.variant == "compact"

        isActivePath : String -> Bool
        isActivePath path =
            if path == "/" then
                UrlPath.toRelative page.path == ""

            else
                let
                    currentPathStr =
                        UrlPath.toRelative page.path

                    relativePath =
                        String.dropLeft 1 path
                in
                currentPathStr == relativePath || String.startsWith (relativePath ++ "/") currentPathStr

        closeMenu =
            toMsg (SharedMsg CloseMenu)
    in
    { body =
        Layout.view
            { site = config
            , strings = uiStrings
            , attributes = [ classes [ Tw.min_h_screen, Tw.flex, Tw.flex_col ] ]
            , home = { href = "/", onClick = Nothing }
            , links =
                sharedData.navItems
                    |> List.map
                        (\item ->
                            { label = item.title
                            , href = item.path
                            , mobileOnly = item.mobileOnly
                            , isActive = isActivePath item.path
                            }
                        )
            , headerActions =
                if config.navbar.showDesktopSearch then
                    [ viewNavbarSearchForm uiStrings isCompact ]

                else
                    []
            , showHeader = True
            , menu =
                Just
                    { isOpen = model.menuOpen
                    , onToggle = toMsg (SharedMsg ToggleMenu)
                    , onClose = closeMenu
                    , content =
                        \links ->
                            [ Html.nav [ classes [ Tw.p s4 ] ] [ viewMobileSearchForm uiStrings closeMenu ]
                            , Html.nav [ classes [ Tw.p s4, Tw.pt s1 ] ] [ links ]
                            ]
                    }
            , main =
                Html.main_
                    [ Attr.id "main-content"
                    , classes [ Tw.flex_1, TwEx.max_w_5xl, Tw.mx_auto, Tw.px s6, Tw.py s10, Tw.w_full ]
                    ]
                    pageView.body
            , aboveFooter = []
            , footer = Just { topMargin = True, extra = [] }
            , scrollToTop =
                Just
                    { visible = model.scrollY > 200
                    , onClick = toMsg (SharedMsg ScrollToTop)
                    , clearRightColumn = False
                    }
            , toasts = Nothing
            , overlays = []
            }
    , title = pageView.title
    }


{-| The layout strings of the language the site is built in.
-}
strings : Data -> UiStrings
strings sharedData =
    UiStrings.forLang sharedData.config.lang


viewNavbarSearchForm : UiStrings -> Bool -> Html msg
viewNavbarSearchForm uiStrings isCompact =
    let
        visibility =
            if isCompact then
                Bp.md [ Tw.flex ]

            else
                Bp.sm [ Tw.flex ]
    in
    Html.form
        [ Attr.action "/haku"
        , Attr.method "GET"
        , classes
            [ Tw.hidden
            , visibility
            , Tw.items_center
            , Tw.gap s2
            , Tw.ml s4
            ]
        ]
        [ Html.label [ Attr.for "navbar-search-input", classes [ Tw.sr_only ] ] [ Html.text uiStrings.search ]
        , Html.input
            [ Attr.id "navbar-search-input"
            , Attr.name "q"
            , Attr.type_ "search"
            , Attr.placeholder uiStrings.search
            , classes
                [ Tw.w_full
                , Bp.md [ TwEx.max_w_2xl ]
                , Tw.rounded_md
                , Tw.border
                , Tw.border_simple TC.borderBrand
                , Tw.bg_simple TC.bgPage
                , Tw.px s2
                , Tw.py s1
                , Tw.type_body_small
                , Tw.text_simple TC.textPrimary
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
                ]
            ]
            []
        , Html.button
            [ Attr.type_ "submit"
            , classes
                [ Tw.rounded_md
                , Tw.border
                , Tw.border_simple TC.brandYellow
                , Tw.bg_simple TC.brandYellow
                , Tw.px s2
                , Tw.py s1
                , Tw.type_body_small
                , Tw.text_simple TC.brand
                , Tw.cursor_pointer
                , Bp.hover [ Tw.text_simple TC.brand ]
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                ]
            ]
            [ FeatherIcons.search |> FeatherIcons.withSize 16 |> FeatherIcons.toHtml [] ]
        ]


viewMobileSearchForm : UiStrings -> msg -> Html msg
viewMobileSearchForm uiStrings closeMsg =
    Html.form
        [ Attr.action "/haku"
        , Attr.method "GET"
        , classes
            [ Tw.flex
            , Tw.items_center
            , Tw.gap s2
            ]
        ]
        [ Html.label [ Attr.for "mobile-search-input", classes [ Tw.sr_only ] ] [ Html.text uiStrings.search ]
        , Html.input
            [ Attr.id "mobile-search-input"
            , Attr.name "q"
            , Attr.type_ "search"
            , Attr.placeholder uiStrings.search
            , classes
                [ Tw.w_full
                , Tw.rounded_md
                , Tw.border
                , Tw.border_simple TC.borderDefault
                , Tw.bg_simple TC.bgPage
                , Tw.px s2
                , Tw.py s2
                , Tw.type_body
                , Tw.text_simple TC.textPrimary
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                ]
            ]
            []
        , Html.button
            [ Attr.type_ "submit"
            , Html.Events.onClick closeMsg
            , classes
                [ Tw.rounded_md
                , Tw.bg_simple TC.brand
                , Tw.px s2
                , Tw.py s2
                , Tw.text_simple TC.textOnDark
                , Tw.cursor_pointer
                , Bp.focus_visible [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand ]
                ]
            ]
            [ FeatherIcons.search |> FeatherIcons.withSize 18 |> FeatherIcons.toHtml [] ]
        ]
