port module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder)



-- ── Main ──────────────────────────────────────────────────────────────────────


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- ── SiteMeta ──────────────────────────────────────────────────────────────────


type alias SiteMeta =
    { buildSha : String
    , buildTimestamp : String
    , runId : String
    , owner : String
    , repo : String
    , contentOwner : String
    , contentRepo : String
    , oauthClientId : String
    , oauthProxyUrl : String
    , repoScope : String
    }


siteMetaDecoder : Decoder SiteMeta
siteMetaDecoder =
    Decode.map7
        (\buildSha buildTimestamp runId owner repo oauthClientId oauthProxyUrl ->
            { buildSha = buildSha
            , buildTimestamp = buildTimestamp
            , runId = runId
            , owner = owner
            , repo = repo
            , contentOwner = owner
            , contentRepo = repo
            , oauthClientId = oauthClientId
            , oauthProxyUrl = oauthProxyUrl
            , repoScope = "public_repo"
            }
        )
        (Decode.field "buildSha" Decode.string)
        (Decode.field "buildTimestamp" Decode.string)
        (Decode.field "runId" Decode.string)
        (Decode.field "owner" Decode.string)
        (Decode.field "repo" Decode.string)
        (Decode.field "oauthClientId" Decode.string)
        (Decode.field "oauthProxyUrl" Decode.string
            |> Decode.maybe
            |> Decode.map (Maybe.withDefault "")
        )
        |> Decode.andThen
            (\meta ->
                Decode.field "repoScope" Decode.string
                    |> Decode.maybe
                    |> Decode.map (Maybe.withDefault "public_repo")
                    |> Decode.map (\scope -> { meta | repoScope = scope })
            )
        |> Decode.andThen
            (\meta ->
                Decode.field "contentOwner" Decode.string
                    |> Decode.maybe
                    |> Decode.map (Maybe.withDefault "")
                    |> Decode.map
                        (\v ->
                            { meta
                                | contentOwner =
                                    if String.isEmpty v then
                                        meta.owner

                                    else
                                        v
                            }
                        )
            )
        |> Decode.andThen
            (\meta ->
                Decode.field "contentRepo" Decode.string
                    |> Decode.maybe
                    |> Decode.map (Maybe.withDefault "")
                    |> Decode.map
                        (\v ->
                            { meta
                                | contentRepo =
                                    if String.isEmpty v then
                                        meta.repo

                                    else
                                        v
                            }
                        )
            )


defaultSiteMeta : SiteMeta
defaultSiteMeta =
    { buildSha = ""
    , buildTimestamp = ""
    , runId = ""
    , owner = ""
    , repo = ""
    , contentOwner = ""
    , contentRepo = ""
    , oauthClientId = ""
    , oauthProxyUrl = ""
    , repoScope = "public_repo"
    }



-- ── Model ─────────────────────────────────────────────────────────────────────


type AuthState
    = NotLoggedIn
    | RequestingDeviceCode
    | AwaitingUserAuth DeviceCodeState
    | LoggedIn Token
    | PATEntry String
    | AuthError String


type alias DeviceCodeState =
    { userCode : String
    , verificationUri : String
    , deviceCode : String
    , interval : Int
    }


type alias Token =
    { value : String
    , login : String
    }


type alias FileMeta =
    { path : String
    , name : String
    , sha : String
    }


type alias EditSession =
    { file : FileMeta
    , originalSha : String
    , content : String
    , commitMessage : String
    , commitState : CommitState
    , pendingDraft : Maybe String
    }


type CommitState
    = Idle
    | Committing
    | CommitError String


type EditorState
    = NoBrowserOpen
    | LoadingFiles
    | FileBrowser (List FileMeta)
    | LoadingFile FileMeta
    | Editing EditSession


type BuildStatus
    = BuildIdle
    | PollingActions { commitSha : String, attempt : Int }
    | PollingPage { commitSha : String, attempt : Int }
    | BuildLive { commitSha : String, pageUrl : String }
    | BuildTimedOut
    | BuildFailed String


type alias Model =
    { auth : AuthState
    , siteMeta : SiteMeta
    , editorState : EditorState
    , buildStatus : BuildStatus
    }



-- ── Init ──────────────────────────────────────────────────────────────────────


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        siteMeta =
            case Decode.decodeValue siteMetaDecoder flags of
                Ok meta ->
                    meta

                Err _ ->
                    defaultSiteMeta
    in
    ( { auth = PATEntry ""
      , siteMeta = siteMeta
      , editorState = NoBrowserOpen
      , buildStatus = BuildIdle
      }
    , loadTokenFromStorage ()
    )



-- ── Msg ───────────────────────────────────────────────────────────────────────


type Msg
    = ClickedLoginWithGitHub
    | ClickedUsePAT
    | ClickedLogout
    | PATChanged String
    | PATSubmitted
    | DeviceCodeReceived (Result String DeviceCodeState)
    | TokenReceived (Result String String)
    | TokenLoadedFromStorage (Maybe String)
    | ClickedBrowseFiles
    | FilesListed (Result String (List FileMeta))
    | ClickedFile FileMeta
    | FileLoaded (Result String { meta : FileMeta, content : String })
    | EditorContentChanged String
    | DraftLoaded (Maybe String)
    | ResumedDraft
    | DiscardedDraft
    | CommitMessageChanged String
    | ClickedCommit
    | CommitResultReceived (Result String String)
    | BuildStatusUpdated BuildStatusEvent


type BuildStatusEvent
    = ActionsQueued
    | ActionsRunning
    | ActionsComplete
    | ActionsFailed String
    | PageShaMatched String
    | PollTimedOut



-- ── Update ────────────────────────────────────────────────────────────────────


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLoginWithGitHub ->
            ( { model | auth = RequestingDeviceCode }
            , requestDeviceCode
                { clientId = model.siteMeta.oauthClientId
                , proxyUrl = model.siteMeta.oauthProxyUrl
                }
            )

        ClickedUsePAT ->
            ( { model | auth = PATEntry "" }, Cmd.none )

        PATChanged v ->
            ( { model | auth = PATEntry v }, Cmd.none )

        PATSubmitted ->
            case model.auth of
                PATEntry v ->
                    if String.isEmpty (String.trim v) then
                        ( model, Cmd.none )

                    else
                        ( { model | auth = LoggedIn { value = v, login = "pat-user" } }
                        , storeToken v
                        )

                _ ->
                    ( model, Cmd.none )

        DeviceCodeReceived (Ok state) ->
            ( { model | auth = AwaitingUserAuth state }
            , startPolling state
            )

        DeviceCodeReceived (Err err) ->
            ( { model | auth = AuthError err }, Cmd.none )

        TokenReceived (Ok token) ->
            ( { model | auth = LoggedIn { value = token, login = "" } }
            , storeToken token
            )

        TokenReceived (Err err) ->
            ( { model | auth = AuthError err }, Cmd.none )

        TokenLoadedFromStorage (Just token) ->
            ( { model | auth = LoggedIn { value = token, login = "" } }, Cmd.none )

        TokenLoadedFromStorage Nothing ->
            ( model, Cmd.none )

        ClickedLogout ->
            ( { model | auth = PATEntry "" }
            , clearToken ()
            )

        ClickedBrowseFiles ->
            case model.auth of
                LoggedIn token ->
                    ( { model | editorState = LoadingFiles }
                    , listFiles
                        { token = token.value
                        , owner = model.siteMeta.contentOwner
                        , repo = model.siteMeta.contentRepo
                        , path = "template"
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        FilesListed (Ok files) ->
            ( { model | editorState = FileBrowser files }, Cmd.none )

        FilesListed (Err _) ->
            ( { model | editorState = NoBrowserOpen }, Cmd.none )

        ClickedFile meta ->
            case model.auth of
                LoggedIn token ->
                    ( { model | editorState = LoadingFile meta }
                    , fetchFile
                        { token = token.value
                        , owner = model.siteMeta.contentOwner
                        , repo = model.siteMeta.contentRepo
                        , path = meta.path
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        FileLoaded (Ok { meta, content }) ->
            let
                session =
                    { file = meta
                    , originalSha = meta.sha
                    , content = content
                    , commitMessage = "Update " ++ meta.name
                    , commitState = Idle
                    , pendingDraft = Nothing
                    }
            in
            ( { model | editorState = Editing session }
            , Cmd.batch
                [ mountEditor ()
                , setEditorContent content
                , loadDraft meta.path
                ]
            )

        FileLoaded (Err _) ->
            ( model, Cmd.none )

        EditorContentChanged newContent ->
            case model.editorState of
                Editing session ->
                    ( { model | editorState = Editing { session | content = newContent } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        DraftLoaded maybeDraft ->
            case ( model.editorState, maybeDraft ) of
                ( Editing session, Just draft ) ->
                    ( { model | editorState = Editing { session | pendingDraft = Just draft } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ResumedDraft ->
            case model.editorState of
                Editing session ->
                    case session.pendingDraft of
                        Just draft ->
                            ( { model | editorState = Editing { session | content = draft, pendingDraft = Nothing } }
                            , setEditorContent draft
                            )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        DiscardedDraft ->
            case model.editorState of
                Editing session ->
                    ( { model | editorState = Editing { session | pendingDraft = Nothing } }
                    , clearDraft session.file.path
                    )

                _ ->
                    ( model, Cmd.none )

        CommitMessageChanged commitMsg ->
            case model.editorState of
                Editing session ->
                    ( { model | editorState = Editing { session | commitMessage = commitMsg } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickedCommit ->
            case ( model.editorState, model.auth ) of
                ( Editing session, LoggedIn token ) ->
                    ( { model | editorState = Editing { session | commitState = Committing } }
                    , commitFile
                        { token = token.value
                        , owner = model.siteMeta.contentOwner
                        , repo = model.siteMeta.contentRepo
                        , path = session.file.path
                        , content = session.content
                        , sha = session.originalSha
                        , message = session.commitMessage
                        }
                    )

                _ ->
                    ( model, Cmd.none )

        CommitResultReceived (Ok commitSha) ->
            case ( model.editorState, model.auth ) of
                ( Editing session, LoggedIn token ) ->
                    let
                        pageUrl =
                            "https://"
                                ++ model.siteMeta.owner
                                ++ ".github.io/"
                                ++ model.siteMeta.repo
                                ++ "/"
                                ++ (session.file.path
                                        |> String.replace "template/" ""
                                        |> String.replace ".md" "/"
                                   )
                    in
                    ( { model
                        | editorState = Editing { session | commitState = Idle }
                        , buildStatus = PollingActions { commitSha = commitSha, attempt = 0 }
                      }
                    , Cmd.batch
                        [ clearDraft session.file.path
                        , startBuildPolling
                            { commitSha = commitSha
                            , token = token.value
                            , owner = model.siteMeta.owner
                            , repo = model.siteMeta.repo
                            , pageUrl = pageUrl
                            , actionsIntervalMs = 15000
                            , pageIntervalMs = 30000
                            , timeoutMs = 600000
                            }
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        CommitResultReceived (Err errMsg) ->
            case model.editorState of
                Editing session ->
                    ( { model | editorState = Editing { session | commitState = CommitError errMsg } }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        BuildStatusUpdated event ->
            let
                next =
                    case ( model.buildStatus, event ) of
                        ( _, PollTimedOut ) ->
                            BuildTimedOut

                        ( _, ActionsFailed reason ) ->
                            BuildFailed reason

                        ( PollingActions state, ActionsComplete ) ->
                            PollingPage { commitSha = state.commitSha, attempt = 0 }

                        ( PollingPage state, PageShaMatched pageUrl ) ->
                            BuildLive { commitSha = state.commitSha, pageUrl = pageUrl }

                        _ ->
                            model.buildStatus
            in
            ( { model | buildStatus = next }, Cmd.none )



-- ── Subscriptions ─────────────────────────────────────────────────────────────


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ deviceCodeReceived (decodeDeviceCode >> DeviceCodeReceived)
        , tokenReceived (decodeToken >> TokenReceived)
        , tokenLoadedFromStorage TokenLoadedFromStorage
        , filesListed (decodeFileList >> FilesListed)
        , fileLoaded (decodeFileLoaded >> FileLoaded)
        , editorContentChanged EditorContentChanged
        , draftLoaded DraftLoaded
        , commitDone (decodeCommitResult >> CommitResultReceived)
        , buildStatusUpdate (decodeBuildStatusEvent >> BuildStatusUpdated)
        ]



-- ── View ──────────────────────────────────────────────────────────────────────


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "min-h-screen bg-bg-subtle flex flex-col" ]
        [ viewNav model
        , viewBuildStatus model.buildStatus
        , Html.main_ [ Attr.class "flex-1 max-w-5xl mx-auto w-full px-6 py-8" ]
            [ case model.auth of
                NotLoggedIn ->
                    viewPATEntry ""

                PATEntry draft ->
                    viewPATEntry draft

                LoggedIn _ ->
                    viewEditorState model.editorState

                AuthError err ->
                    viewCard []
                        [ Html.p [ Attr.class "text-brand-red mb-4" ] [ Html.text ("Error: " ++ err) ]
                        , btnSecondary [ Events.onClick ClickedUsePAT ] "Try again"
                        ]

                _ ->
                    Html.text ""
            ]
        ]


viewNav : Model -> Html Msg
viewNav model =
    Html.nav [ Attr.class "bg-brand shadow-sm" ]
        [ Html.div [ Attr.class "max-w-5xl mx-auto px-6 py-3 flex items-center justify-between" ]
            [ Html.a [ Attr.href "/" ]
                [ Html.img
                    [ Attr.src "https://logo.palikkaharrastajat.fi/logo/horizontal/svg/horizontal-full-dark.svg"
                    , Attr.alt "Suomen Palikkaharrastajat ry"
                    , Attr.class "h-14"
                    ]
                    []
                ]
            , case model.auth of
                LoggedIn token ->
                    Html.div [ Attr.class "flex items-center gap-4" ]
                        [ Html.span [ Attr.class "type-caption text-white/70" ]
                            [ Html.text
                                (if String.isEmpty token.login then
                                    "Logged in"

                                 else
                                    "Signed in as " ++ token.login
                                )
                            ]
                        , Html.button
                            [ Events.onClick ClickedLogout
                            , Attr.class "type-caption text-white/70 hover:text-white underline"
                            ]
                            [ Html.text "Log out" ]
                        ]

                _ ->
                    Html.text ""
            ]
        ]


viewPATEntry : String -> Html Msg
viewPATEntry draft =
    viewCard [ Attr.class "max-w-md mx-auto" ]
        [ Html.h2 [ Attr.class "type-h3 text-text-primary mb-2" ]
            [ Html.text "Personal Access Token" ]
        , Html.p [ Attr.class "type-caption text-text-muted mb-4" ]
            [ Html.text "Paste a GitHub Personal Access Token with repo scope." ]
        , Html.div [ Attr.class "flex gap-2" ]
            [ Html.input
                [ Attr.type_ "password"
                , Attr.value draft
                , Attr.placeholder "ghp_..."
                , Events.onInput PATChanged
                , Attr.class "flex-1 border border-border-default rounded-lg px-3 py-2 type-caption focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-yellow"
                ]
                []
            , btnPrimary [ Events.onClick PATSubmitted ] "Save"
            ]
        ]


viewEditorState : EditorState -> Html Msg
viewEditorState editorState =
    case editorState of
        NoBrowserOpen ->
            viewCard [ Attr.class "max-w-sm mx-auto text-center" ]
                [ Html.p [ Attr.class "text-text-muted mb-4" ]
                    [ Html.text "Browse the content directory to pick a file to edit." ]
                , btnPrimary [ Events.onClick ClickedBrowseFiles ] "Browse files"
                ]

        LoadingFiles ->
            Html.p [ Attr.class "text-text-muted" ] [ Html.text "Loading files…" ]

        FileBrowser files ->
            Html.div []
                [ Html.h2 [ Attr.class "type-h4 text-text-primary mb-4" ]
                    [ Html.text "Choose a file" ]
                , Html.ul [ Attr.class "divide-y divide-border-default border border-border-default rounded-lg overflow-hidden bg-bg-page shadow-sm" ]
                    (List.map
                        (\f ->
                            Html.li []
                                [ Html.button
                                    [ Events.onClick (ClickedFile f)
                                    , Attr.class "w-full text-left px-4 py-3 type-caption text-text-primary hover:bg-bg-subtle hover:text-brand motion-safe:transition-colors"
                                    ]
                                    [ Html.text f.name ]
                                ]
                        )
                        files
                    )
                ]

        LoadingFile meta ->
            Html.p [ Attr.class "text-text-muted" ]
                [ Html.text ("Loading " ++ meta.name ++ "…") ]

        Editing session ->
            Html.div [ Attr.class "flex flex-col gap-4" ]
                [ Html.div [ Attr.class "flex items-center justify-between" ]
                    [ Html.h2 [ Attr.class "type-h4 text-text-primary" ]
                        [ Html.text ("Editing: " ++ session.file.name) ]
                    ]
                , case session.pendingDraft of
                    Just _ ->
                        Html.div [ Attr.class "bg-brand-yellow/10 border border-brand-yellow/40 rounded-lg px-4 py-3 flex items-center gap-3 type-caption" ]
                            [ Html.span [ Attr.class "text-brand flex-1" ]
                                [ Html.text "You have an unsaved draft." ]
                            , btnSecondary [ Events.onClick ResumedDraft ] "Resume draft"
                            , Html.button
                                [ Events.onClick DiscardedDraft
                                , Attr.class "type-caption text-text-muted hover:text-text-primary underline"
                                ]
                                [ Html.text "Discard" ]
                            ]

                    Nothing ->
                        Html.text ""
                , Html.div [ Attr.id "cm-editor" ] []
                , Html.div [ Attr.class "flex items-center gap-3 flex-wrap" ]
                    [ Html.input
                        [ Attr.type_ "text"
                        , Attr.value session.commitMessage
                        , Attr.placeholder "Commit message"
                        , Events.onInput CommitMessageChanged
                        , Attr.class "flex-1 min-w-0 border border-border-default rounded-lg px-3 py-2 type-caption focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-yellow"
                        ]
                        []
                    , Html.button
                        [ Events.onClick ClickedCommit
                        , Attr.disabled (session.commitState == Committing)
                        , Attr.class
                            ("inline-flex items-center px-4 py-2 rounded-lg type-body-small motion-safe:transition-colors "
                                ++ (if session.commitState == Committing then
                                        "bg-brand-yellow/40 text-brand cursor-not-allowed"

                                    else
                                        "bg-brand-yellow text-brand hover:bg-brand hover:text-brand-yellow"
                                   )
                            )
                        ]
                        [ Html.text
                            (if session.commitState == Committing then
                                "Committing…"

                             else
                                "Commit & Push"
                            )
                        ]
                    , case session.commitState of
                        CommitError err ->
                            Html.p [ Attr.class "w-full type-caption text-brand-red" ]
                                [ Html.text ("Error: " ++ err) ]

                        _ ->
                            Html.text ""
                    ]
                ]


viewBuildStatus : BuildStatus -> Html Msg
viewBuildStatus status =
    case status of
        BuildIdle ->
            Html.text ""

        PollingActions _ ->
            Html.div [ Attr.class "build-status polling" ]
                [ Html.text "⏳ Build queued / running…" ]

        PollingPage _ ->
            Html.div [ Attr.class "build-status polling" ]
                [ Html.text "🚀 Build complete, waiting for deploy…" ]

        BuildLive { pageUrl } ->
            Html.div [ Attr.class "build-status live" ]
                [ Html.text "✅ Live! "
                , Html.a [ Attr.href pageUrl, Attr.target "_blank", Attr.class "underline hover:no-underline" ]
                    [ Html.text "View updated page" ]
                ]

        BuildTimedOut ->
            Html.div [ Attr.class "build-status error" ]
                [ Html.text "⚠️ Deploy timed out. Check GitHub Actions." ]

        BuildFailed reason ->
            Html.div [ Attr.class "build-status error" ]
                [ Html.text ("❌ Build failed: " ++ reason) ]



-- ── Reusable UI helpers ────────────────────────────────────────────────────


viewCard : List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg
viewCard attrs children =
    Html.div
        (Attr.class "bg-bg-page border border-border-default rounded-xl shadow-sm p-6" :: attrs)
        children


btnPrimary : List (Html.Attribute Msg) -> String -> Html Msg
btnPrimary attrs label =
    Html.button
        (Attr.class "inline-flex items-center justify-center px-4 py-2 rounded-lg type-body-small text-brand bg-brand-yellow hover:bg-brand hover:text-brand-yellow motion-safe:transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            :: attrs
        )
        [ Html.text label ]


btnSecondary : List (Html.Attribute Msg) -> String -> Html Msg
btnSecondary attrs label =
    Html.button
        (Attr.class "inline-flex items-center justify-center px-4 py-2 rounded-lg type-body-small text-brand bg-white border border-brand/40 hover:bg-brand/5 motion-safe:transition-colors"
            :: attrs
        )
        [ Html.text label ]



-- ── Port stubs ────────────────────────────────────────────────────────────────


port requestDeviceCode : { clientId : String, proxyUrl : String } -> Cmd msg


port startPolling : DeviceCodeState -> Cmd msg


port loadTokenFromStorage : () -> Cmd msg


port storeToken : String -> Cmd msg


port clearToken : () -> Cmd msg


port deviceCodeReceived : (Decode.Value -> msg) -> Sub msg


port tokenReceived : (Decode.Value -> msg) -> Sub msg


port tokenLoadedFromStorage : (Maybe String -> msg) -> Sub msg


port listFiles : { token : String, owner : String, repo : String, path : String } -> Cmd msg


port filesListed : (Decode.Value -> msg) -> Sub msg


port fetchFile : { token : String, owner : String, repo : String, path : String } -> Cmd msg


port fileLoaded : (Decode.Value -> msg) -> Sub msg


port setEditorContent : String -> Cmd msg


port editorContentChanged : (String -> msg) -> Sub msg


port mountEditor : () -> Cmd msg


port saveDraft : { path : String, content : String } -> Cmd msg


port loadDraft : String -> Cmd msg


port draftLoaded : (Maybe String -> msg) -> Sub msg


port clearDraft : String -> Cmd msg


port commitFile :
    { token : String
    , owner : String
    , repo : String
    , path : String
    , content : String
    , sha : String
    , message : String
    }
    -> Cmd msg


port commitDone : (Decode.Value -> msg) -> Sub msg


port startBuildPolling :
    { commitSha : String
    , token : String
    , owner : String
    , repo : String
    , pageUrl : String
    , actionsIntervalMs : Int
    , pageIntervalMs : Int
    , timeoutMs : Int
    }
    -> Cmd msg


port buildStatusUpdate : (Decode.Value -> msg) -> Sub msg



-- ── Helpers ───────────────────────────────────────────────────────────────────


decodeDeviceCode : Decode.Value -> Result String DeviceCodeState
decodeDeviceCode =
    Decode.decodeValue
        (Decode.map4 DeviceCodeState
            (Decode.field "userCode" Decode.string)
            (Decode.field "verificationUri" Decode.string)
            (Decode.field "deviceCode" Decode.string)
            (Decode.field "interval" Decode.int)
        )
        >> Result.mapError Decode.errorToString


decodeToken : Decode.Value -> Result String String
decodeToken =
    Decode.decodeValue (Decode.field "token" Decode.string)
        >> Result.mapError Decode.errorToString


decodeFileList : Decode.Value -> Result String (List FileMeta)
decodeFileList =
    Decode.decodeValue
        (Decode.list
            (Decode.map3 FileMeta
                (Decode.field "path" Decode.string)
                (Decode.field "name" Decode.string)
                (Decode.field "sha" Decode.string)
            )
        )
        >> Result.mapError Decode.errorToString


decodeFileLoaded : Decode.Value -> Result String { meta : FileMeta, content : String }
decodeFileLoaded =
    Decode.decodeValue
        (Decode.map2 (\meta content -> { meta = meta, content = content })
            (Decode.field "meta"
                (Decode.map3 FileMeta
                    (Decode.field "path" Decode.string)
                    (Decode.field "name" Decode.string)
                    (Decode.field "sha" Decode.string)
                )
            )
            (Decode.field "content" Decode.string)
        )
        >> Result.mapError Decode.errorToString


decodeCommitResult : Decode.Value -> Result String String
decodeCommitResult =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.field "sha" Decode.string |> Decode.map Ok
            , Decode.field "error" Decode.string |> Decode.map Err
            ]
        )
        >> Result.withDefault (Err "Unknown error")


decodeBuildStatusEvent : Decode.Value -> BuildStatusEvent
decodeBuildStatusEvent value =
    case Decode.decodeValue (Decode.field "event" Decode.string) value of
        Ok "actionsQueued" ->
            ActionsQueued

        Ok "actionsRunning" ->
            ActionsRunning

        Ok "actionsComplete" ->
            ActionsComplete

        Ok "pageMatched" ->
            Decode.decodeValue (Decode.field "pageUrl" Decode.string) value
                |> Result.withDefault ""
                |> PageShaMatched

        Ok "timedOut" ->
            PollTimedOut

        Ok "actionsFailed" ->
            Decode.decodeValue (Decode.field "reason" Decode.string) value
                |> Result.withDefault "unknown"
                |> ActionsFailed

        _ ->
            PollTimedOut
