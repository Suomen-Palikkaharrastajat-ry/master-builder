module Component.LoadState exposing (State(..), view, badge)

{-| Remote data state helpers for page-level loading, error, and empty states.

To connect with `krisajenkins/remotedata` without taking a package dependency:

    fromRemoteData : RemoteData.RemoteData e a -> LoadState.State e a
    fromRemoteData rd =
        case rd of
            RemoteData.NotAsked ->
                LoadState.NotAsked

            RemoteData.Loading ->
                LoadState.Loading

            RemoteData.Failure e ->
                LoadState.Failure e

            RemoteData.Success a ->
                LoadState.Success a

@docs State, view, badge

-}

import Component.Alert as Alert
import Component.Button as Button
import Component.Spinner as Spinner
import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC


{-| Remote load state representation.
-}
type State e a
    = NotAsked
    | Loading
    | Failure e
    | Success a


{-| Renders loading spinner, failure alert with optional retry button, or page content.
-}
view :
    { loadingLabel : String
    , errorMessage : e -> String
    , onRetry : Maybe msg
    , retryLabel : String
    }
    -> State e a
    -> (a -> Html msg)
    -> Html msg
view config state renderSuccess =
    case state of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div
                [ classes [ Tw.flex, Tw.justify_center, Tw.py Th.s8 ] ]
                [ Spinner.view { size = Spinner.Medium, label = config.loadingLabel } ]

        Failure err ->
            let
                errorMsg =
                    config.errorMessage err

                bodyContent =
                    case config.onRetry of
                        Just retryMsg ->
                            [ Html.p [] [ Html.text errorMsg ]
                            , Html.div [ classes [ Tw.mt Th.s2 ] ]
                                [ Button.new { label = config.retryLabel, onClick = retryMsg }
                                    |> Button.withSize Button.Small
                                    |> Button.toHtml
                                ]
                            ]

                        Nothing ->
                            [ Html.p [] [ Html.text errorMsg ] ]
            in
            Alert.view
                { alertType = Alert.Error
                , title = Nothing
                , body = bodyContent
                , customIcon = Nothing
                , onDismiss = Nothing
                }

        Success data ->
            renderSuccess data


{-| Floating status badge for maps and dashboards.
-}
badge :
    { loadingLabel : String
    , errorMessage : e -> String
    }
    -> State e a
    -> Html msg
badge config state =
    case state of
        NotAsked ->
            Html.text ""

        Loading ->
            Html.div
                [ classes
                    [ Tw.absolute
                    , TwEx.top_4
                    , TwEx.left_half
                    , TwEx.neg_translate_x_half
                    , Tw.bg_simple TC.bgPage
                    , Tw.text_simple TC.textMuted
                    , Tw.rounded
                    , Tw.shadow
                    , Tw.px Th.s4
                    , Tw.py Th.s2
                    , Tw.type_caption
                    , Tw.z_40
                    ]
                , Attr.attribute "role" "status"
                ]
                [ Html.text config.loadingLabel ]

        Failure err ->
            Html.div
                [ classes
                    [ Tw.absolute
                    , TwEx.top_4
                    , TwEx.left_half
                    , TwEx.neg_translate_x_half
                    , TwEx.bg_brand_red_10
                    , Tw.text_simple TC.brandRed
                    , Tw.rounded
                    , Tw.shadow
                    , Tw.px Th.s4
                    , Tw.py Th.s2
                    , Tw.type_caption
                    , Tw.z_40
                    ]
                , Attr.attribute "role" "alert"
                ]
                [ Html.text (config.errorMessage err) ]

        Success _ ->
            Html.text ""
