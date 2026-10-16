module PocketBaseAuth exposing
    ( AuthState(..), AuthUser, isAuthenticated, getToken
    , decodeAuthUser, restoreAuthFromFlags
    , encodeAuthUser, authUserModelJson, userFromPopupResult
    )

{-| PocketBase authentication helpers: token restore from flags, user JSON
decoding and encoding and popup results.

The matching JavaScript lives in `js/pocketbase-auth.js`.


# State

@docs AuthState, AuthUser, isAuthenticated, getToken


# Decoding and storing

@docs decodeAuthUser, restoreAuthFromFlags
@docs encodeAuthUser, authUserModelJson, userFromPopupResult

-}

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
