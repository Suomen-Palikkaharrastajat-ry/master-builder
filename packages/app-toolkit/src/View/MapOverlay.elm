module View.MapOverlay exposing (Position(..), panel, filterGroup, detailPanel, detailPanelWithHeaderActions)

{-| Overlay panel components for interactive maps (controls, filters, and selection detail panels).

Provides responsive positioning and accessible containers for map controls without inline styles.

@docs Position, panel, filterGroup, detailPanel, detailPanelWithHeaderActions

-}

import FeatherIcons
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode
import View.Icons exposing (featherIcon)


{-| Corner or edge anchor positions for overlay panels over map viewports.
-}
type Position
    = TopCenter
    | TopLeft
    | TopRight
    | BottomLeft
    | BottomRight


{-| Floating map control panel positioned relative to the map viewport.
Renders as `<section aria-label=...>` when a label is provided, or `<div>` otherwise.
-}
panel : { position : Position, label : Maybe String } -> List (Html msg) -> Html msg
panel config children =
    let
        classes =
            "absolute z-[1000] bg-bg-page/90 backdrop-blur rounded shadow p-4 "
                ++ positionClasses config.position
    in
    case config.label of
        Just lbl ->
            Html.node "section"
                [ Attr.class classes
                , Attr.attribute "aria-label" lbl
                ]
                children

        Nothing ->
            Html.div
                [ Attr.class classes ]
                children


{-| Accessible `<fieldset>` with `<legend>` container for filter toggle groups.
-}
filterGroup : { legend : String } -> List (Html msg) -> Html msg
filterGroup config children =
    Html.fieldset
        [ Attr.class "flex flex-col gap-2 border-0 p-0 m-0" ]
        (Html.legend [ Attr.class "sr-only" ] [ Html.text config.legend ]
            :: children
        )


{-| Responsive detail panel for displaying selected marker information.
Renders as a right-side drawer on desktop (`md+`) and a bottom sheet on mobile (`< md`).
Includes an accessible close button and Escape key listener.
-}
detailPanel :
    { isOpen : Bool
    , onClose : msg
    , closeLabel : String
    , title : String
    }
    -> List (Html msg)
    -> Html msg
detailPanel config children =
    detailPanelWithHeaderActions
        { isOpen = config.isOpen
        , onClose = config.onClose
        , closeLabel = config.closeLabel
        , title = config.title
        , headerActions = []
        }
        children


{-| Variant of `detailPanel` supporting extra action elements in the header
(e.g. an edit button alongside the close button).
-}
detailPanelWithHeaderActions :
    { isOpen : Bool
    , onClose : msg
    , closeLabel : String
    , title : String
    , headerActions : List (Html msg)
    }
    -> List (Html msg)
    -> Html msg
detailPanelWithHeaderActions config children =
    if not config.isOpen then
        Html.text ""

    else
        Html.node "aside"
            [ Attr.id "map-detail-panel"
            , Attr.attribute "role" "region"
            , Attr.attribute "aria-label" config.title
            , Attr.tabindex -1
            , onEscape config.onClose
            , Attr.class "absolute inset-x-0 bottom-0 max-h-[80vh] md:max-h-full md:inset-y-0 md:right-0 md:left-auto md:w-[22rem] z-[1010] bg-bg-page shadow-xl overflow-y-auto flex flex-col rounded-t-xl md:rounded-none"
            ]
            [ Html.div
                [ Attr.class "flex items-start justify-between gap-2 p-4 border-b border-border-default" ]
                ([ Html.h2
                    [ Attr.class "type-h4 text-text-primary flex-1" ]
                    [ Html.text config.title ]
                 ]
                    ++ config.headerActions
                    ++ [ closeButton config.onClose config.closeLabel ]
                )
            , Html.div
                [ Attr.class "p-4 flex-1 space-y-3" ]
                children
            ]


closeButton : msg -> String -> Html msg
closeButton onClose closeLabel =
    Html.button
        [ Attr.type_ "button"
        , Attr.id "map-detail-close"
        , Events.onClick onClose
        , Attr.attribute "aria-label" closeLabel
        , Attr.class "text-text-subtle hover:text-text-primary mt-0.5 flex-shrink-0 cursor-pointer"
        ]
        [ featherIcon FeatherIcons.x 24 ]


onEscape : msg -> Html.Attribute msg
onEscape onClose =
    Events.on "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Escape" then
                        Decode.succeed onClose

                    else
                        Decode.fail "not escape"
                )
        )


positionClasses : Position -> String
positionClasses pos =
    case pos of
        TopCenter ->
            "top-4 left-1/2 -translate-x-1/2"

        TopLeft ->
            "top-4 left-4"

        TopRight ->
            "top-4 right-4"

        BottomLeft ->
            "bottom-8 left-4"

        BottomRight ->
            "bottom-8 right-4"
