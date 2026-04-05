module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

{-| Shared layout shell: navbar, footer, and mobile drawer.
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Browser.Events
import Component.Footer as Footer
import Component.MobileDrawer as MobileDrawer
import Component.Navbar as Navbar
import Config exposing (Config)
import ContentDir
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
import Tailwind.Theme exposing (s0, s1, s10, s14, s2, s4, s6, white)
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
    , slug : String
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
                Glob.succeed identity
                    |> Glob.match (Glob.literal (dir ++ "/"))
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
                                            (dir ++ "/" ++ slug ++ ".md")
                                            |> BackendTask.allowFatal
                                    )
                                |> BackendTask.combine
                        )
            )
        |> BackendTask.map
            (List.filter (\fm -> fm.nav /= NavHidden)
                >> List.map
                    (\fm ->
                        { title = Maybe.withDefault fm.title fm.navTitle
                        , slug = fm.slug
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

        logoHtml =
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
                        [ Attr.src config.branding.logoLight
                        , Attr.alt config.branding.logoAlt
                        , classes [ Tw.h s10, Bp.sm [ Tw.h s14 ] ]
                        ]
                        []
                    ]
                ]

        hamburgerHtml =
            Html.button
                [ classes [ Bp.sm [ Tw.hidden ], Tw.text_simple white, Tw.p s2, Tw.ml s2, Tw.rounded, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.cursor_pointer ]
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

        navLinks =
            sharedData.navItems
                |> List.map
                    (\item ->
                        { label = item.title
                        , href =
                            if item.slug == "index" then
                                "/"

                            else
                                "/" ++ item.slug
                        , mobileOnly = item.mobileOnly
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
                        , variant = Navbar.Dark
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
                        , disclaimer = Just config.footer.disclaimer
                        }
                    , MobileDrawer.viewOverlay { isOpen = model.menuOpen, onClose = toMsg (SharedMsg CloseMenu), breakpoint = MobileDrawer.Sm }
                    , viewMobileDrawer page.path model (toMsg << SharedMsg) sharedData.navItems
                    ]
                ]
            , title = pageView.title
            }


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
        , breakpoint = MobileDrawer.Sm
        , content =
            [ Html.nav [ classes [ Tw.p s4 ] ]
                [ Html.ul [ classes [ Tw.flex, Tw.flex_col, Tw.gap s1, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                    (List.map
                        (\item ->
                            let
                                href =
                                    if item.slug == "index" then
                                        "/"

                                    else
                                        "/" ++ item.slug
                            in
                            MobileDrawer.viewNavLink
                                { href = href
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
