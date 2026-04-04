module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

{-| Shared layout shell: navbar, footer, and mobile drawer.
-}

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
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme exposing (s0, s0_dot_5, s1, s10, s12, s14, s16, s2, s3, s4, s6, s8, white)
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
                    , classes
                        [ Tw.sr_only
                        , Bp.focus [ Tw.not_sr_only, Tw.fixed, TwEx.top_2, TwEx.left_2, Tw.z_50, Tw.px s4, Tw.py s2, Tw.bg_simple TC.brandYellow, Tw.text_simple TC.brand, Tw.type_body_small, Tw.rounded ]
                        , Bp.focus_visible [ Tw.ring_2, TwEx.ring_brand ]
                        ]
                    ]
                    [ Html.text "Siirry pääsisältöön" ]
                , Html.div [ classes [ Tw.min_h_screen, Tw.flex, Tw.flex_col ] ]
                    [ viewNavbar model (toMsg << SharedMsg) navItems
                    , Html.main_ [ Attr.id "main-content", classes [ Tw.flex_1, TwEx.max_w_5xl, Tw.mx_auto, Tw.px s6, Tw.py s10, Tw.w_full ] ] pageView.body
                    , viewFooter
                    , MobileDrawer.viewOverlay { isOpen = model.menuOpen, onClose = toMsg (SharedMsg CloseMenu), breakpoint = MobileDrawer.Sm }
                    , viewMobileDrawer page.path model (toMsg << SharedMsg) navItems
                    ]
                ]
            , title = pageView.title
            }


viewNavbar : Model -> (SharedMsg -> msg) -> List NavItem -> Html msg
viewNavbar model toMsg navItems =
    Html.nav
        [ classes [ Tw.bg_simple TC.brand, Tw.sticky, TwEx.top_0, Tw.z_50, Tw.shadow_md ] ]
        [ Html.div
            [ classes [ TwEx.max_w_5xl, Tw.mx_auto, Tw.px s4 ] ]
            [ Html.div
                [ classes [ Tw.flex, Tw.items_center, Tw.py s2, Bp.sm [ Tw.py s3 ] ] ]
                [ Html.a
                    [ Attr.href "/"
                    , classes [ Tw.shrink_0, Tw.mr_auto, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.rounded ]
                    , Html.Events.onClick (toMsg CloseMenu)
                    ]
                    [ Html.node "picture"
                        []
                        [ Html.node "source"
                            [ Attr.attribute "media" "(min-width: 640px)"
                            , Attr.attribute "srcset" "/logo/horizontal/svg/horizontal-full-dark-bold.svg"
                            ]
                            []
                        , Html.img
                            [ Attr.src "/logo/horizontal/svg/horizontal.svg"
                            , Attr.alt "Suomen Palikkaharrastajat ry"
                            , classes [ Tw.h s10, Bp.sm [ Tw.h s14 ] ]
                            ]
                            []
                        ]
                    ]
                , Html.button
                    [ classes [ Bp.sm [ Tw.hidden ], Tw.text_simple white, Tw.p s2, Tw.ml s2, Tw.rounded, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.cursor_pointer ]
                    , Html.Events.onClick (toMsg ToggleMenu)
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
                , Html.ul
                    [ classes [ Bp.sm [ Tw.flex ], Tw.hidden, Tw.flex_wrap, Tw.gap s0_dot_5, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                    (List.map navLink navItems)
                ]
            ]
        ]


navLink : NavItem -> Html msg
navLink item =
    Html.li []
        [ Html.a
            [ Attr.href ("/" ++ item.slug)
            , classes
                [ TwEx.text_white_80
                , Bp.hover [ Tw.text_simple TC.brandYellow ]
                , Tw.font_medium
                , Tw.px s2
                , Bp.sm [ Tw.px s3 ]
                , Tw.py s1
                , Tw.rounded
                , Tw.transition_colors
                , Tw.text_sm
                , Tw.cursor_pointer
                , Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
                ]
            ]
            [ Html.text item.title ]
        ]


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
        [ classes [ Tw.bg_simple TC.brand, Tw.text_simple white, Tw.mt s16, Tw.py s12, Tw.px s4 ] ]
        [ Html.div
            [ classes [ TwEx.max_w_5xl, Tw.mx_auto ] ]
            [ Html.div
                [ classes [ Tw.grid, Tw.grid_cols_1, Bp.sm [ TwEx.grid_cols_auto_1fr ], Tw.gap s8, Bp.sm [ Tw.items_end ] ] ]
                [ -- Col 1: service links + logo
                  Html.div [ classes [ Tw.flex, Tw.items_start, Tw.gap s4 ] ]
                    [ Html.img
                        [ Attr.src "/logo/square/svg/square-smile-full-dark-bold.svg"
                        , Attr.alt ""
                        , Attr.attribute "aria-hidden" "true"
                        , classes [ TwEx.h_35, TwEx.w_35, Tw.shrink_0 ]
                        ]
                        []
                    , Html.div [ classes [ TwEx.space_y s3 ] ]
                        [ Html.p [ classes [ Tw.text_xs, Tw.font_semibold, TwEx.text_white_50, Tw.uppercase, Tw.tracking_wider ] ]
                            [ Html.text "Palikkaharrastajat" ]
                        , Html.div [ classes [ Tw.flex, Tw.gap s4 ] ]
                            [ Html.ul [ classes [ TwEx.space_y s2, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                                [ Html.li []
                                    [ Html.a
                                        [ Attr.href "https://forum.palikkaharrastajat.fi"
                                        , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple white ], Tw.underline, Tw.transition_colors ]
                                        ]
                                        [ Html.text "Jäsenfoorumi" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://kortti.palikkaharrastajat.fi"
                                        , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple white ], Tw.underline, Tw.transition_colors ]
                                        ]
                                        [ Html.text "Jäsenkortti" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://maksut.palikkaharrastajat.fi"
                                        , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple white ], Tw.underline, Tw.transition_colors ]
                                        ]
                                        [ Html.text "Jäsenmaksu" ]
                                    ]
                                ]
                            , Html.ul [ classes [ TwEx.space_y s2, Tw.list_none, Tw.m s0, Tw.p s0 ] ]
                                [ Html.li []
                                    [ Html.a
                                        [ Attr.href "https://kalenteri.palikkaharrastajat.fi"
                                        , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple white ], Tw.underline, Tw.transition_colors ]
                                        ]
                                        [ Html.text "Palikkakalenteri" ]
                                    ]
                                , Html.li []
                                    [ Html.a
                                        [ Attr.href "https://linkit.palikkaharrastajat.fi"
                                        , classes [ Tw.text_sm, TwEx.text_white_80, Bp.hover [ Tw.text_simple white ], Tw.underline, Tw.transition_colors ]
                                        ]
                                        [ Html.text "Palikkalinkit" ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , -- Col 2: org name & legal
                  Html.div [ classes [ TwEx.space_y s1, Bp.sm [ Tw.text_right ] ] ]
                    [ Html.div [ classes [ TwEx.space_y s1, Tw.text_xs, TwEx.text_white_50 ] ]
                        [ Html.p [] [ Html.text "© 2026 Suomen Palikkaharrastajat ry" ]
                        , Html.p [] [ Html.text "LEGO® on LEGO Groupin rekisteröity tavaramerkki" ]
                        ]
                    ]
                ]
            ]
        ]
