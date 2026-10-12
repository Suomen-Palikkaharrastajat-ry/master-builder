module Component.Layout exposing (Config, Menu, menuButtonId, view)

{-| The page shell shared by every site in the family: skip link, header,
mobile drawer, main area, footer, scroll-to-top button and toast region.

A site supplies its resolved configuration, the layout strings of the current
language and the parts that differ (navigation links, header actions, page
content); the shell decides how they are put together.

@docs Config, Menu, menuButtonId, view

-}

import Component.Footer.Family as Family
import Component.MobileDrawer as MobileDrawer
import Component.Navbar as Navbar
import Component.ScrollToTop as ScrollToTop
import Component.SkipLink as SkipLink
import Component.Toast as Toast
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import SiteSettings exposing (SiteSettings)
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import UiStrings exposing (UiStrings)


{-| State and content of the mobile menu.

`content` receives the drawer's list of navigation links and returns everything
the drawer shows, so a site can put a search form above the links, account
controls below them, or replace them altogether.

-}
type alias Menu msg =
    { isOpen : Bool
    , onToggle : msg
    , onClose : msg
    , content : Html msg -> List (Html msg)
    }


{-| Everything a site hands to the shell.

  - `site`, `strings` — configuration and layout strings of the current language.
  - `attributes` — attributes of the container around header, main and footer.
  - `home` — where the brand links to, and an optional click handler.
  - `links` — navigation links, shown in the header and in the drawer.
  - `headerActions` — controls on the right of the header (search, sign in).
  - `showHeader` — `False` leaves the header out (embedded views).
  - `menu` — the mobile menu; `Nothing` leaves out the menu button and drawer.
  - `main` — the site's `<main id="main-content">`.
  - `aboveFooter` — full-width blocks between main and footer.
  - `footer` — `Nothing` on pages without a footer.
  - `scrollToTop` — `Nothing` on sites without the floating button.
  - `toasts` — notifications of the live region; `Nothing` leaves the region out.
  - `overlays` — anything else rendered over the page.

-}
type alias Config msg =
    { site : SiteSettings
    , strings : UiStrings
    , attributes : List (Html.Attribute msg)
    , home : { href : String, onClick : Maybe msg }
    , links : List Navbar.NavLink
    , headerActions : List (Html msg)
    , showHeader : Bool
    , menu : Maybe (Menu msg)
    , main : Html msg
    , aboveFooter : List (Html msg)
    , footer : Maybe { topMargin : Bool, extra : List (Html msg) }
    , scrollToTop : Maybe { visible : Bool, onClick : msg, clearRightColumn : Bool }
    , toasts : Maybe (List (Toast.Toast msg))
    , overlays : List (Html msg)
    }


drawerId : String
drawerId =
    "mobile-nav"


{-| Id of the element holding the menu button, so a site can return focus to
it when the drawer closes.
-}
menuButtonId : String
menuButtonId =
    "mobile-menu-button"


{-| The page shell, as the list of body nodes.
-}
view : Config msg -> List (Html msg)
view config =
    [ SkipLink.view { target = "main-content", label = config.strings.skipToContent }
    , Html.div config.attributes
        (List.concat
            [ if config.showHeader then
                [ viewHeader config ]

              else
                []
            , [ config.main ]
            , config.aboveFooter
            , case config.footer of
                Just options ->
                    [ Family.view options config.site.footer ]

                Nothing ->
                    []
            , case config.menu of
                Just menu ->
                    [ MobileDrawer.viewOverlay
                        { isOpen = menu.isOpen
                        , onClose = menu.onClose
                        , breakpoint = drawerBreakpoint config
                        }
                    , MobileDrawer.view
                        { isOpen = menu.isOpen
                        , id = drawerId
                        , label = config.strings.mobileMenu
                        , closeLabel = config.strings.closeMenu
                        , onClose = menu.onClose
                        , breakpoint = drawerBreakpoint config
                        , content = menu.content (viewDrawerLinks config menu)
                        }
                    ]

                Nothing ->
                    []
            , case config.scrollToTop of
                Just button ->
                    [ ScrollToTop.view
                        { visible = button.visible
                        , onClick = button.onClick
                        , label = config.strings.backToTop
                        , clearRightColumn = button.clearRightColumn
                        }
                    ]

                Nothing ->
                    []
            ]
        )
    ]
        ++ (case config.toasts of
                Just toasts ->
                    [ Toast.region
                        { label = config.strings.notifications
                        , closeLabel = config.strings.close
                        }
                        toasts
                    ]

                Nothing ->
                    []
           )
        ++ config.overlays


isStandard : Config msg -> Bool
isStandard config =
    config.site.navbar.variant == "standard"


{-| The standard header keeps its links visible from `sm`; the others from `md`.
-}
drawerBreakpoint : Config msg -> MobileDrawer.Breakpoint
drawerBreakpoint config =
    if isStandard config then
        MobileDrawer.Sm

    else
        MobileDrawer.Md


viewDrawerLinks : Config msg -> Menu msg -> Html msg
viewDrawerLinks config menu =
    Html.ul [ classes [ Tw.flex, Tw.flex_col, Tw.gap Th.s1, Tw.list_none, Tw.m Th.s0, Tw.p Th.s0 ] ]
        (List.map
            (\link ->
                MobileDrawer.viewNavLink
                    { href = link.href
                    , label = link.label
                    , isActive = link.isActive
                    , onClose = menu.onClose
                    }
            )
            config.links
        )


viewHeader : Config msg -> Html msg
viewHeader config =
    case config.site.navbar.variant of
        "app" ->
            Navbar.viewAppHeader
                { brand =
                    Navbar.viewBrand
                        { href = config.home.href
                        , iconSrc = config.site.branding.logoSquare
                        , title = config.site.site.title
                        , onClick = config.home.onClick
                        }
                , navLabel = config.strings.mainNav
                , links = config.links
                , trailing = config.headerActions
                , menuToggle =
                    config.menu
                        |> Maybe.map
                            (\menu ->
                                Html.span [ Attr.id menuButtonId ]
                                    [ Navbar.viewMenuToggle
                                        { isOpen = menu.isOpen
                                        , onToggle = menu.onToggle
                                        , controls = drawerId
                                        , openLabel = config.strings.openMenu
                                        , closeLabel = config.strings.closeMenu
                                        }
                                    ]
                            )
                , sticky = config.site.navbar.sticky
                }

        _ ->
            Navbar.view
                { logo = viewSiteLogo config
                , links = config.links
                , mobileMenuToggle = Maybe.map (viewSiteMenuToggle config) config.menu
                , action =
                    case config.headerActions of
                        [] ->
                            Nothing

                        [ action ] ->
                            Just action

                        actions ->
                            Just (Html.div [ classes [ Tw.flex, Tw.items_center, Tw.gap Th.s2 ] ] actions)
                , sticky = config.site.navbar.sticky
                , variant =
                    if isStandard config then
                        Navbar.Dark

                    else
                        Navbar.Compact
                }


{-| Following the brand link closes an open menu, unless the site handles the
click itself.
-}
brandClick : Config msg -> List (Html.Attribute msg)
brandClick config =
    case ( config.home.onClick, config.menu ) of
        ( Just msg, _ ) ->
            [ Events.onClick msg ]

        ( Nothing, Just menu ) ->
            [ Events.onClick menu.onClose ]

        ( Nothing, Nothing ) ->
            []


viewSiteLogo : Config msg -> Html msg
viewSiteLogo config =
    let
        branding =
            config.site.branding
    in
    if isStandard config then
        Html.a
            ([ Attr.href config.home.href
             , classes [ Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.rounded ]
             ]
                ++ brandClick config
            )
            [ Html.node "picture"
                []
                [ Html.node "source"
                    [ Attr.attribute "media" "(min-width: 640px)"
                    , Attr.attribute "srcset" branding.logoDark
                    ]
                    []
                , Html.img
                    [ Attr.src branding.logoLightMobile
                    , Attr.alt branding.logoAlt
                    , classes [ Tw.h Th.s10, Bp.sm [ Tw.h Th.s14 ] ]
                    ]
                    []
                ]
            ]

    else
        Html.a
            ([ Attr.href config.home.href
             , classes [ Tw.flex, Tw.items_center, Tw.gap Th.s2, Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ], Tw.rounded ]
             ]
                ++ brandClick config
            )
            [ Html.img
                [ Attr.src branding.logoSquare
                , Attr.alt ""
                , Attr.attribute "aria-hidden" "true"
                , classes [ Tw.h Th.s8, Tw.w Th.s8 ]
                ]
                []
            , Html.span
                [ classes [ Tw.type_h4, Tw.text_simple Th.white ] ]
                [ Html.text config.site.site.title ]
            ]


viewSiteMenuToggle : Config msg -> Menu msg -> Html msg
viewSiteMenuToggle config menu =
    Html.button
        [ classes
            [ if isStandard config then
                Bp.sm [ Tw.hidden ]

              else
                Bp.md [ Tw.hidden ]
            , Tw.text_simple Th.white
            , Tw.p Th.s2
            , Tw.ml Th.s2
            , Tw.rounded
            , Bp.focus [ Tw.outline_none, Tw.ring_2, TwEx.ring_brand_yellow ]
            , Tw.cursor_pointer
            ]
        , Attr.type_ "button"
        , Attr.id menuButtonId
        , Events.onClick menu.onToggle
        , Attr.attribute "aria-label"
            (if menu.isOpen then
                config.strings.closeMenu

             else
                config.strings.openMenu
            )
        , Attr.attribute "aria-expanded"
            (if menu.isOpen then
                "true"

             else
                "false"
            )
        , Attr.attribute "aria-controls" drawerId
        ]
        [ (if menu.isOpen then
            FeatherIcons.x

           else
            FeatherIcons.menu
          )
            |> FeatherIcons.withSize 24
            |> FeatherIcons.toHtml [ Attr.attribute "aria-hidden" "true", Attr.attribute "focusable" "false" ]
        ]
