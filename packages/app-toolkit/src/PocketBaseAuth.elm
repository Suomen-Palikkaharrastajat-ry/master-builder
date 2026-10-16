module PocketBaseAuth exposing
    ( AuthState(..), AuthUser, isAuthenticated, getToken
    , decodeAuthUser, decodeOAuthUserResponse, restoreAuthFromFlags
    , encodeAuthUser, authUserModelJson, userFromPopupResult
    , callbackQuery, callbackRedirectUrl
    , fetchOAuthToken, fetchOAuthUser
    )

{-| PocketBase authentication helpers: token restore from flags, user JSON
decoding and encoding, popup results, legacy `#/callback` redirect helpers, and
msg-polymorphic OAuth2 token exchange.

The matching JavaScript lives in `js/pocketbase-auth.js`.


# State

@docs AuthState, AuthUser, isAuthenticated, getToken


# Decoding and storing

@docs decodeAuthUser, decodeOAuthUserResponse, restoreAuthFromFlags
@docs encodeAuthUser, authUserModelJson, userFromPopupResult


# Legacy redirect flow

@docs callbackQuery, callbackRedirectUrl


# Token exchange

@docs fetchOAuthToken, fetchOAuthUser

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Url exposing (Url)


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


{-| Whether the state holds a signed-in user.
-}
isAuthenticated : AuthState -> Bool
isAuthenticated state =
    case state of
        Authenticated _ ->
            True

        NotAuthenticated ->
            False


{-| The signed-in user's token, if any.
-}
getToken : AuthState -> Maybe String
getToken state =
    case state of
        Authenticated user ->
            Just user.token

        NotAuthenticated ->
            Nothing


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


{-| Encode the user as `{ id, name, email }`. The token is left out: it is
stored separately.
-}
encodeAuthUser : AuthUser -> Encode.Value
encodeAuthUser user =
    Encode.object
        [ ( "id", Encode.string user.id )
        , ( "name", Encode.string user.name )
        , ( "email", Encode.string user.email )
        ]


{-| `encodeAuthUser` as a string, the `model` of the `saveAuthToken` port.
Quotes and backslashes in the name are escaped.
-}
authUserModelJson : AuthUser -> String
authUserModelJson user =
    Encode.encode 0 (encodeAuthUser user)


{-| Turn the `oauthPopupResult` port payload into a user. An empty token (the
script's way of reporting a failed or cancelled popup) or an undecodable model
gives `Nothing`.
-}
userFromPopupResult : { token : String, model : String } -> Maybe AuthUser
userFromPopupResult { token, model } =
    if String.isEmpty token then
        Nothing

    else
        Decode.decodeString decodeAuthUser model
            |> Result.toMaybe
            |> Maybe.map (\user -> { user | token = token })


{-| The `code` and `state` of an OAuth redirect to `#/callback?code=…&state=…`.
Values are percent-decoded (`+` is a space); a missing parameter is `Nothing`.

Legacy: the popup sign-in (`authWithOAuth2`) never redirects to `#/callback`.

-}
callbackQuery : Url -> { code : Maybe String, state : Maybe String }
callbackQuery url =
    let
        pairs =
            case url.fragment of
                Just fragment ->
                    case String.split "?" fragment of
                        _ :: rest :: more ->
                            String.join "?" (rest :: more)
                                |> String.split "&"
                                |> List.filterMap pair

                        _ ->
                            []

                Nothing ->
                    []

        pair part =
            case String.split "=" part of
                key :: valueParts ->
                    let
                        raw =
                            String.join "=" valueParts
                    in
                    Just ( key, String.replace "+" " " raw |> Url.percentDecode |> Maybe.withDefault raw )

                [] ->
                    Nothing

        find key =
            pairs
                |> List.filter (\( k, _ ) -> k == key)
                |> List.head
                |> Maybe.map Tuple.second
    in
    { code = find "code", state = find "state" }


{-| The redirect URL to send PocketBase with the code: the current page without
query and fragment, plus `#/callback`. It must match what the sign-in popup used.
-}
callbackRedirectUrl : Url -> String
callbackRedirectUrl url =
    Url.toString { url | query = Nothing, fragment = Nothing } ++ "#/callback"


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
    fetchOAuthUser pbBaseUrl code codeVerifier redirectUrl state (Result.map Authenticated >> toMsg)
