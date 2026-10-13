module Component.Account exposing (User, viewHeader, viewDrawer)

{-| Account controls of an app: a sign-in button, or the signed-in name with a
sign-out button. One version for the header (shown from `md` up) and one for
the mobile drawer.

@docs User, viewHeader, viewDrawer

-}

import Component.Button as Button
import Html exposing (Html)
import Html.Attributes as Attr
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx
import TailwindTokens as TC
import UiStrings exposing (UiStrings)


{-| What the controls show of a signed-in user.
-}
type alias User a =
    { a | name : String, email : String }


type alias Config a msg =
    { strings : UiStrings
    , user : Maybe (User a)
    , onSignIn : msg
    , onSignOut : msg
    }


{-| Controls for the dark header; hidden below `md`, where the drawer has them.
-}
viewHeader : Config a msg -> Html msg
viewHeader config =
    Html.div [ classes [ Tw.hidden, Bp.md [ Tw.flex ], Tw.gap Th.s2, Tw.items_center ] ]
        (case config.user of
            Nothing ->
                [ button config.onSignIn config.strings.signIn ]

            Just user ->
                [ Html.span [ classes [ Tw.type_caption, TwEx.text_white_80 ] ] [ Html.text user.name ]
                , signOut config user
                ]
        )


{-| Controls for the mobile drawer.
-}
viewDrawer : Config a msg -> Html msg
viewDrawer config =
    case config.user of
        Nothing ->
            Html.div [ classes [ Tw.flex ] ] [ button config.onSignIn config.strings.signIn ]

        Just user ->
            Html.div [ classes [ Tw.flex, Tw.flex_col, Tw.items_start, Tw.gap Th.s3 ] ]
                [ Html.span [ classes [ Tw.type_caption, Tw.text_simple TC.textMuted ] ] [ Html.text user.name ]
                , signOut config user
                ]


signOut : Config a msg -> User a -> Html msg
signOut config user =
    Html.span [ Attr.title (tooltip config.strings user), classes [ Tw.inline_flex ] ]
        [ button config.onSignOut config.strings.signOut ]


button : msg -> String -> Html msg
button msg label =
    Button.new { label = label, onClick = msg }
        |> Button.withVariant Button.Primary
        |> Button.withSize Button.Small
        |> Button.toHtml


{-| "Signed in: Name (email)", leaving out whichever part is empty.
-}
tooltip : UiStrings -> User a -> String
tooltip strings user =
    let
        name =
            String.trim user.name

        email =
            String.trim user.email
    in
    if String.isEmpty name then
        strings.signedInAs ++ email

    else if String.isEmpty email then
        strings.signedInAs ++ name

    else
        strings.signedInAs ++ name ++ " (" ++ email ++ ")"
