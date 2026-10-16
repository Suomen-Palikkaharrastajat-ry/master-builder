module PocketBaseAuthTest exposing (suite)

{-| Test suite for PocketBaseAuth module.
-}

import Expect
import Json.Decode as Decode
import PocketBaseAuth
    exposing
        ( AuthState(..)
        , AuthUser
        , authUserModelJson
        , decodeAuthUser
        , getToken
        , isAuthenticated
        , restoreAuthFromFlags
        , userFromPopupResult
        )
import Test exposing (Test, describe, test)


alice : AuthUser
alice =
    { id = "u1", name = "Alice", email = "alice@example.com", token = "jwt" }


suite : Test
suite =
    describe "PocketBaseAuth"
        [ describe "decodeAuthUser"
            [ test "decodes full user JSON correctly" <|
                \_ ->
                    let
                        rawJson =
                            """{"id":"usr123","name":"Matti Meikäläinen","email":"matti@example.com"}"""
                    in
                    case Decode.decodeString decodeAuthUser rawJson of
                        Ok user ->
                            Expect.all
                                [ \u -> Expect.equal "usr123" u.id
                                , \u -> Expect.equal "Matti Meikäläinen" u.name
                                , \u -> Expect.equal "matti@example.com" u.email
                                , \u -> Expect.equal "" u.token
                                ]
                                user

                        Err err ->
                            Expect.fail (Decode.errorToString err)
            , test "tolerates missing name and email fields" <|
                \_ ->
                    let
                        rawJson =
                            """{"id":"usr456"}"""
                    in
                    case Decode.decodeString decodeAuthUser rawJson of
                        Ok user ->
                            Expect.all
                                [ \u -> Expect.equal "usr456" u.id
                                , \u -> Expect.equal "" u.name
                                , \u -> Expect.equal "" u.email
                                ]
                                user

                        Err err ->
                            Expect.fail (Decode.errorToString err)
            , test "fails without an id" <|
                \_ ->
                    Decode.decodeString decodeAuthUser """{"name":"x"}"""
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "fails on invalid JSON" <|
                \_ ->
                    Decode.decodeString decodeAuthUser "not json"
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "treats a null name and email as empty" <|
                \_ ->
                    Decode.decodeString decodeAuthUser """{"id":"a","name":null,"email":null}"""
                        |> Expect.equal (Ok { id = "a", name = "", email = "", token = "" })
            ]
        , describe "restoreAuthFromFlags"
            [ test "restores Authenticated state when both token and valid model are present" <|
                \_ ->
                    let
                        token =
                            Just "jwt-token-xyz"

                        model =
                            Just """{"id":"usr123","name":"Teemu","email":"teemu@example.com"}"""
                    in
                    case restoreAuthFromFlags token model of
                        Authenticated user ->
                            Expect.all
                                [ \u -> Expect.equal "usr123" u.id
                                , \u -> Expect.equal "Teemu" u.name
                                , \u -> Expect.equal "jwt-token-xyz" u.token
                                ]
                                user

                        NotAuthenticated ->
                            Expect.fail "Expected Authenticated state"
            , test "returns NotAuthenticated when token is missing" <|
                \_ ->
                    let
                        model =
                            Just """{"id":"usr123","name":"Teemu","email":"teemu@example.com"}"""
                    in
                    restoreAuthFromFlags Nothing model
                        |> Expect.equal NotAuthenticated
            , test "returns NotAuthenticated when model is missing" <|
                \_ ->
                    restoreAuthFromFlags (Just "jwt-token-xyz") Nothing
                        |> Expect.equal NotAuthenticated
            , test "returns NotAuthenticated when model is malformed JSON" <|
                \_ ->
                    restoreAuthFromFlags (Just "jwt-token-xyz") (Just "{bad-json}")
                        |> Expect.equal NotAuthenticated
            ]
        , describe "isAuthenticated and getToken"
            [ test "signed in" <|
                \_ ->
                    Expect.equal ( True, Just "jwt" ) ( isAuthenticated (Authenticated alice), getToken (Authenticated alice) )
            , test "signed out" <|
                \_ ->
                    Expect.equal ( False, Nothing ) ( isAuthenticated NotAuthenticated, getToken NotAuthenticated )
            ]
        , describe "authUserModelJson"
            [ test "leaves the token out" <|
                \_ ->
                    authUserModelJson alice
                        |> Expect.equal """{"id":"u1","name":"Alice","email":"alice@example.com"}"""
            , test "round-trips names with quotes and backslashes" <|
                \_ ->
                    let
                        tricky =
                            { alice | name = "A \"Q\" \\ B" }
                    in
                    Decode.decodeString decodeAuthUser (authUserModelJson tricky)
                        |> Expect.equal (Ok { tricky | token = "" })
            ]
        , describe "userFromPopupResult"
            [ test "builds the user with the token" <|
                \_ ->
                    userFromPopupResult { token = "jwt", model = authUserModelJson alice }
                        |> Expect.equal (Just alice)
            , test "empty token means a failed popup" <|
                \_ ->
                    userFromPopupResult { token = "", model = "{}" }
                        |> Expect.equal Nothing
            , test "undecodable model gives Nothing" <|
                \_ ->
                    userFromPopupResult { token = "jwt", model = "{}" }
                        |> Expect.equal Nothing
            ]
        ]
