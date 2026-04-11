module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

{-| Shared layout shell: navbar, footer, and mobile drawer.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import Browser.Events
import Component.Footer as Footer
import Component.MobileDrawer as MobileDrawer
import Component.Navbar as Navbar
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
import Json.Decode
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Ports
import Route exposing (Route(..))
import SharedTemplate exposing (SharedTemplate)
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s0, s1, s10, s14, s2, s4, s6, s8, white)
import TailwindExtra as TwEx
import TailwindTokens as TC
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
            (List.filter (\item -> item.frontmatter.nav /= NavHidden)
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

        isCompact =
            config.navbar.variant == "compact"

        logoHtml =
            if isCompact then
                Html.a
                    [ Attr.href "/"
                    , classes [ Tw.flex, Tw.items_center, Tw.gap s2, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.rounded ]
                    , Html.Events.onClick (toMsg (SharedMsg CloseMenu))
                    ]
                    [ Html.img
                        [ Attr.src config.branding.logoSquare
                        , Attr.alt ""
                        , Attr.attribute "aria-hidden" "true"
                        , classes [ Tw.h s8, Tw.w s8 ]
                        ]
                        []
                    , Html.span
                        [ classes [ Tw.type_h4, Tw.text_simple white ] ]
                        [ Html.text config.site.title ]
                    ]

            else
                Html.a
                    [ Attr.href "/"
                    , classes [ Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.rounded ]
                    , Html.Events.onClick (toMsg (SharedMsg CloseMenu))
                    ]
                    [ Html.node "picture"
                        []
                        [ Html.node "source"
                            [ Attr.attribute "media" "(min-width: 640px)"
                            , Attr.attribute "srcset" config.branding.logoDark
                            ]
                            []
                        , Html.img
                            [ Attr.src config.branding.logoLightMobile
                            , Attr.alt config.branding.logoAlt
                            , classes [ Tw.h s10, Bp.sm [ Tw.h s14 ] ]
                            ]
                            []
                        ]
                    ]

        hamburgerBreakpointHidden =
            if isCompact then
                Bp.md [ Tw.hidden ]

            else
                Bp.sm [ Tw.hidden ]

        hamburgerHtml =
            Html.button
                [ classes [ hamburgerBreakpointHidden, Tw.text_simple white, Tw.p s2, Tw.ml s2, Tw.rounded, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.cursor_pointer ]
                , Html.Events.onClick (toMsg (SharedMsg ToggleMenu))
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
                ]
                [ if model.menuOpen then
                    FeatherIcons.x |> FeatherIcons.withSize 24 |> FeatherIcons.toHtml []

                  else
                    FeatherIcons.menu |> FeatherIcons.withSize 24 |> FeatherIcons.toHtml []
                ]

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

        navLinks =
            sharedData.navItems
                |> List.map
                    (\item ->
                        { label = item.title
                        , href = item.path
                        , mobileOnly = item.mobileOnly
                        , isActive = isActivePath item.path
                        }
                    )
    in
    case page.route of
        _ ->
            { body =
                [ Html.a
                    [ Attr.href "#main-content"
                    , classes
                        [ Tw.sr_only
                        , Bp.focus [ Tw.not_sr_only, Tw.fixed, TwEx.top_2, TwEx.left_2, Tw.z_50, Tw.px s4, Tw.py s2, Tw.bg_simple TC.brandYellow, Tw.text_simple TC.brand, Tw.type_body_small, Tw.rounded ]
                        , Bp.focus_visible [ Tw.ring_2, TwEx.ring_brand ]
                        ]
                    ]
                    [ Html.text "Siirry pääsisältöön" ]
                , Html.div [ classes [ Tw.min_h_screen, Tw.flex, Tw.flex_col ] ]
                    [ Navbar.view
                        { logo = logoHtml
                        , links = navLinks
                        , mobileMenuToggle = Just hamburgerHtml
                        , action = Nothing
                        , sticky = config.navbar.sticky
                        , variant =
                            if isCompact then
                                Navbar.Compact

                            else
                                Navbar.Dark
                        }
                    , Html.main_ [ Attr.id "main-content", classes [ Tw.flex_1, TwEx.max_w_5xl, Tw.mx_auto, Tw.px s6, Tw.py s10, Tw.w_full ] ] pageView.body
                    , Footer.view
                        { logo =
                            Just
                                (Html.img
                                    [ Attr.src config.footer.footerLogo
                                    , Attr.alt ""
                                    , Attr.attribute "aria-hidden" "true"
                                    , classes [ TwEx.h_35, TwEx.w_35, Tw.shrink_0 ]
                                    ]
                                    []
                                )
                        , siteLabel = Just config.footer.siteLabel
                        , links = config.footer.links
                        , groups = []
                        , copyright = config.footer.copyright
                        , disclaimer =
                            if List.isEmpty config.footer.disclaimer then
                                Nothing

                            else
                                Just config.footer.disclaimer
                        }
                    , MobileDrawer.viewOverlay
                        { isOpen = model.menuOpen
                        , onClose = toMsg (SharedMsg CloseMenu)
                        , breakpoint =
                            if isCompact then
                                MobileDrawer.Md

                            else
                                MobileDrawer.Sm
                        }
                    , viewMobileDrawer page.path
                        model
                        (toMsg << SharedMsg)
                        sharedData.navItems
                        (if isCompact then
                            MobileDrawer.Md

                         else
                            MobileDrawer.Sm
                        )
                    ]
                ]
            , title = pageView.title
            }


viewMobileDrawer : UrlPath -> Model -> (SharedMsg -> msg) -> List NavItem -> MobileDrawer.Breakpoint -> Html msg
viewMobileDrawer currentPath model toMsg navItems breakpoint =
    let
        isActive : String -> Bool
        isActive path =
            if path == "/" then
                UrlPath.toRelative currentPath == ""

            else
                let
                    currentPathStr =
                        UrlPath.toRelative currentPath

                    relativePath =
                        String.dropLeft 1 path
                in
                currentPathStr == relativePath || String.startsWith (relativePath ++ "/") currentPathStr

        close =
            toMsg CloseMenu
    in
    MobileDrawer.view
        { isOpen = model.menuOpen
        , id = "mobile-nav"
        , onClose = close
        , breakpoint = breakpoint
        , content =
            [ Html.nav [ classes [ Tw.p s4 ] ]
                [ Html.ul [ classes [ Tw.flex, Tw.flex_col, Tw.gap s1, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                    (List.map
                        (\item ->
                            MobileDrawer.viewNavLink
                                { href = item.path
                                , label = item.title
                                , isActive = isActive item.path
                                , onClose = close
                                }
                        )
                        navItems
                    )
                ]
            ]
        }
