module PocketBaseAuth exposing (AuthState(..), AuthUser, decodeAuthUser, decodeOAuthUserResponse, fetchOAuthToken, fetchOAuthUser, restoreAuthFromFlags)

{-| PocketBase authentication helpers: token restore from flags, user JSON decoding,
and msg-polymorphic OAuth2 token exchange.

@docs AuthState, AuthUser, decodeAuthUser, decodeOAuthUserResponse, fetchOAuthToken, fetchOAuthUser, restoreAuthFromFlags

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Authenticated PocketBase user details.
-}
type alias AuthUser =
    { id : String
    , name : String
    , email : String
    , token : String
    }


{-| Current authentication state.
-}
type AuthState
    = NotAuthenticated
    | Authenticated AuthUser


{-| JSON decoder for PocketBase user records.
Tolerates missing or null name/email fields by falling back to empty strings.
-}
decodeAuthUser : Decoder AuthUser
decodeAuthUser =
    Decode.map4 AuthUser
        (Decode.field "id" Decode.string)
        (Decode.maybe (Decode.field "name" Decode.string) |> Decode.map (Maybe.withDefault ""))
        (Decode.maybe (Decode.field "email" Decode.string) |> Decode.map (Maybe.withDefault ""))
        (Decode.succeed "")


{-| JSON decoder for the PocketBase OAuth2 response, which contains `token` and `record`.
Returns an `AuthUser` with `token` populated.
-}
decodeOAuthUserResponse : Decoder AuthUser
decodeOAuthUserResponse =
    Decode.map2 (\token user -> { user | token = token })
        (Decode.field "token" Decode.string)
        (Decode.field "record" decodeAuthUser)


{-| Restores authentication state from stored token and user model JSON flags.
Returns `NotAuthenticated` if either value is absent or if the user JSON fails to decode.
-}
restoreAuthFromFlags : Maybe String -> Maybe String -> AuthState
restoreAuthFromFlags maybeToken maybeModel =
    case maybeToken of
        Just token ->
            case maybeModel of
                Just modelStr ->
                    case Decode.decodeString decodeAuthUser modelStr of
                        Ok user ->
                            Authenticated { user | token = token }

                        Err _ ->
                            NotAuthenticated

                Nothing ->
                    NotAuthenticated

        Nothing ->
            NotAuthenticated


{-| Exchange an OAuth2 authorization code and code verifier with PocketBase for an `AuthUser`.
This is msg-polymorphic, allowing any application Msg type to receive the HTTP result.
-}
fetchOAuthUser :
    String
    -> String
    -> String
    -> String
    -> String
    -> (Result Http.Error AuthUser -> msg)
    -> Cmd msg
fetchOAuthUser pbBaseUrl code codeVerifier redirectUrl state toMsg =
    let
        body =
            Encode.object
                [ ( "provider", Encode.string "oidc" )
                , ( "code", Encode.string code )
                , ( "codeVerifier", Encode.string codeVerifier )
                , ( "redirectUrl", Encode.string redirectUrl )
                , ( "state", Encode.string state )
                ]
    in
    Http.post
        { url = pbBaseUrl ++ "/api/collections/users/auth-with-oauth2"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg decodeOAuthUserResponse
        }


{-| Exchange an OAuth2 authorization code and code verifier with PocketBase for an `AuthState`.
This wraps `fetchOAuthUser` and maps `Ok user` to `Ok (Authenticated user)`.
-}
fetchOAuthToken :
    String
    -> String
    -> String
    -> String
    -> String
    -> (Result Http.Error AuthState -> msg)
    -> Cmd msg
fetchOAuthToken pbBaseUrl code codeVerifier redirectUrl state toMsg =
    let
        body =
            Encode.object
                [ ( "provider", Encode.string "oidc" )
                , ( "code", Encode.string code )
                , ( "codeVerifier", Encode.string codeVerifier )
                , ( "redirectUrl", Encode.string redirectUrl )
                , ( "state", Encode.string state )
                ]

        decoder =
            Decode.map Authenticated decodeOAuthUserResponse
    in
    Http.post
        { url = pbBaseUrl ++ "/api/collections/users/auth-with-oauth2"
        , body = Http.jsonBody body
        , expect = Http.expectJson toMsg decoder
        }
