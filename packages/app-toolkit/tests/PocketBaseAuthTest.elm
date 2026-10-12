module PocketBaseAuthTest exposing (suite)

{-| Test suite for PocketBaseAuth module.
-}

import Expect
import Json.Decode as Decode
import PocketBaseAuth
    exposing
        ( AuthState(..)
        , AuthUser
        , decodeAuthUser
        , decodeOAuthUserResponse
        , restoreAuthFromFlags
        )
import Test exposing (Test, describe, test)


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
            ]
        , describe "decodeOAuthUserResponse"
            [ test "decodes OAuth response with token and record" <|
                \_ ->
                    let
                        rawJson =
                            """{"token":"jwt-abc","record":{"id":"usr789","name":"Liisa","email":"liisa@example.com"}}"""
                    in
                    case Decode.decodeString decodeOAuthUserResponse rawJson of
                        Ok user ->
                            Expect.all
                                [ \u -> Expect.equal "usr789" u.id
                                , \u -> Expect.equal "Liisa" u.name
                                , \u -> Expect.equal "liisa@example.com" u.email
                                , \u -> Expect.equal "jwt-abc" u.token
                                ]
                                user

                        Err err ->
                            Expect.fail (Decode.errorToString err)
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
        ]
