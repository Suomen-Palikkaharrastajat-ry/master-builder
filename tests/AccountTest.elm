module AccountTest exposing (suite)

{-| Test suite for Component.Account, the shared sign-in / signed-in controls.
-}

import Component.Account as Account
import Expect
import Html exposing (Html)
import Html.Attributes as Attr
import Lang exposing (Lang(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import UiStrings


type Msg
    = SignIn
    | SignOut


controls : Lang -> Maybe { name : String, email : String } -> Html Msg
controls lang user =
    Html.div []
        [ Account.viewHeader { strings = UiStrings.forLang lang, user = user, onSignIn = SignIn, onSignOut = SignOut }
        , Account.viewDrawer { strings = UiStrings.forLang lang, user = user, onSignIn = SignIn, onSignOut = SignOut }
        ]


suite : Test
suite =
    describe "Component.Account"
        [ test "signed out: a sign-in button in the language, in header and drawer" <|
            \_ ->
                controls En Nothing
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button", Selector.containing [ Selector.text "Sign in" ] ]
                    |> Query.count
                        (\n ->
                            if n == 2 then
                                Expect.pass

                            else
                                Expect.fail ("expected 2 buttons, got " ++ String.fromInt n)
                        )
        , test "signed in: the name, a sign-out button and a tooltip saying who" <|
            \_ ->
                controls Fi (Just { name = "Matti Meikäläinen", email = "matti@example.org" })
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.text "Matti Meikäläinen"
                        , Selector.containing [ Selector.tag "button", Selector.containing [ Selector.text "Kirjaudu ulos" ] ]
                        , Selector.attribute (Attr.title "Kirjautunut: Matti Meikäläinen (matti@example.org)")
                        ]
        , test "an account without a display name shows its email address" <|
            \_ ->
                controls Fi (Just { name = " ", email = "matti@example.org" })
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.text "matti@example.org"
                        , Selector.attribute (Attr.title "Kirjautunut: matti@example.org")
                        ]
        ]
