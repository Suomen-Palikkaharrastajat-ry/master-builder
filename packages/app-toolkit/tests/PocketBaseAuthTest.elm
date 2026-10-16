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
        , callbackQuery
        , callbackRedirectUrl
        , decodeAuthUser
        , decodeOAuthUserResponse
        , getToken
        , isAuthenticated
        , restoreAuthFromFlags
        , userFromPopupResult
        )
import Test exposing (Test, describe, test)
import Url


alice : AuthUser
alice =
    { id = "u1", name = "Alice", email = "alice@example.com", token = "jwt" }


urlWith : String -> Url.Url
urlWith str =
    case Url.fromString str of
        Just url ->
            url

        Nothing ->
            Debug.todo ("bad test url " ++ str)


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
            , test "fails without a token" <|
                \_ ->
                    Decode.decodeString decodeOAuthUserResponse """{"record":{"id":"a"}}"""
                        |> Result.toMaybe
                        |> Expect.equal Nothing
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
        , describe "callbackQuery"
            [ test "reads code and state" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/app/#/callback?code=abc&state=xyz")
                        |> Expect.equal { code = Just "abc", state = Just "xyz" }
            , test "percent-decodes values" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/#/callback?code=a%2Fb%20c&state=s%3D1")
                        |> Expect.equal { code = Just "a/b c", state = Just "s=1" }
            , test "keeps = inside values" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/#/callback?code=a=b==&state=z")
                        |> Expect.equal { code = Just "a=b==", state = Just "z" }
            , test "missing state is Nothing" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/#/callback?code=abc")
                        |> Expect.equal { code = Just "abc", state = Nothing }
            , test "no query gives Nothing for both" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/#/callback")
                        |> Expect.equal { code = Nothing, state = Nothing }
            , test "no fragment gives Nothing for both" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/?code=abc")
                        |> Expect.equal { code = Nothing, state = Nothing }
            , test "keeps a malformed escape as is" <|
                \_ ->
                    callbackQuery (urlWith "https://x.test/#/callback?code=%E0%A4%A&state=s")
                        |> Expect.equal { code = Just "%E0%A4%A", state = Just "s" }
            ]
        , describe "callbackRedirectUrl"
            [ test "drops query and fragment" <|
                \_ ->
                    callbackRedirectUrl (urlWith "https://x.test/app/?a=1#/events?b=2")
                        |> Expect.equal "https://x.test/app/#/callback"
            , test "keeps a port" <|
                \_ ->
                    callbackRedirectUrl (urlWith "http://localhost:5173/")
                        |> Expect.equal "http://localhost:5173/#/callback"
            ]
        ]
