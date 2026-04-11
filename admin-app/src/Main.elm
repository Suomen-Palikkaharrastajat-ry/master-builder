port module Main exposing (main)

import Admin.ComponentCatalog as Catalog
import Browser
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder)
import MarkdownRenderer


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias AdminConfig =
    { enabled : Bool
    , path : String
    , owner : String
    , repo : String
    , branch : String
    , contentPath : String
    }


type alias SiteConfig =
    { title : String
    , logo : String
    , logoAlt : String
    , admin : AdminConfig
    }


type alias Token =
    { value : String
    , remember : Bool
    }


type alias FileMeta =
    { path : String
    , name : String
    , sha : String
    }


type alias Draft =
    { path : String
    , baseSha : String
    , baseContentHash : String
    , content : String
    , staged : Bool
    , conflict : Bool
    }


type alias RemoteSnapshot =
    { path : String
    , sha : String
    , contentHash : String
    , content : String
    }


type alias BuilderState =
    { selectedTag : String
    , values : Dict String String
    , body : String
    }


type AuthState
    = LoggedOut String Bool
    | LoggedIn Token


type LoadState
    = Waiting
    | LoadingFiles
    | LoadingFile String
    | Working
    | Failed String


type ActivePanel
    = FilesPanel
    | EditorPanel
    | PreviewPanel
    | ComponentsPanel


type CommitState
    = CommitIdle
    | CommitRunning
    | CommitSuccess String
    | CommitFailed String
    | CommitConflicts (List String)


type alias Model =
    { config : SiteConfig
    , auth : AuthState
    , files : List FileMeta
    , drafts : Dict String Draft
    , remoteSnapshots : Dict String RemoteSnapshot
    , selectedPath : Maybe String
    , editorContent : String
    , loadState : LoadState
    , activePanel : ActivePanel
    , builder : BuilderState
    , commitMessage : String
    , commitState : CommitState
    , newFilePath : String
    }


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        config =
            siteConfigFromFlags flags

        firstSpec =
            Catalog.all
                |> List.head
                |> Maybe.withDefault
                    { tag = "callout"
                    , label = "Callout"
                    , description = ""
                    , attributes = []
                    , body = Just "Content"
                    }

        model =
            { config = config
            , auth = LoggedOut "" False
            , files = []
            , drafts = Dict.empty
            , remoteSnapshots = Dict.empty
            , selectedPath = Nothing
            , editorContent = ""
            , loadState = Waiting
            , activePanel = FilesPanel
            , builder =
                { selectedTag = firstSpec.tag
                , values = Catalog.initialValues firstSpec
                , body = Maybe.withDefault "" firstSpec.body
                }
            , commitMessage = "Update content"
            , commitState = CommitIdle
            , newFilePath = ""
            }
    in
    ( model
    , Cmd.batch
        [ loadToken ()
        , loadWorkspace (workspaceKey config)
        ]
    )


type Msg
    = TokenInputChanged String
    | RememberChanged Bool
    | SubmittedToken
    | TokenLoaded (Maybe Token)
    | ClickedLogout
    | ClickedRefreshFiles
    | FilesListed (Result String (List FileMeta))
    | ClickedFile String
    | FileLoaded (Result String { meta : FileMeta, content : String })
    | EditorChanged String
    | WorkspaceLoaded (List Draft)
    | ToggledStage String
    | CommitMessageChanged String
    | ClickedCommit
    | CommitReturned CommitResult
    | NewFilePathChanged String
    | ClickedCreateFile
    | ClickedDiscardLocal String
    | ClickedKeepLocal String
    | SwitchedPanel ActivePanel
    | SelectedComponent String
    | BuilderAttrChanged String String
    | BuilderBodyChanged String
    | InsertedComponent


type CommitResult
    = CommitOk String
    | CommitError String
    | CommitConflictPaths (List String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TokenInputChanged token ->
            case model.auth of
                LoggedOut _ remember ->
                    ( { model | auth = LoggedOut token remember }, Cmd.none )

                LoggedIn _ ->
                    ( model, Cmd.none )

        RememberChanged remember ->
            case model.auth of
                LoggedOut token _ ->
                    ( { model | auth = LoggedOut token remember }, Cmd.none )

                LoggedIn _ ->
                    ( model, Cmd.none )

        SubmittedToken ->
            case model.auth of
                LoggedOut token remember ->
                    let
                        cleanToken =
                            String.trim token
                    in
                    if String.isEmpty cleanToken then
                        ( model, Cmd.none )

                    else
                        ( { model | auth = LoggedIn { value = cleanToken, remember = remember } }
                        , Cmd.batch
                            [ storeToken { token = cleanToken, remember = remember }
                            , listFilesCmd model cleanToken
                            ]
                        )

                LoggedIn _ ->
                    ( model, Cmd.none )

        TokenLoaded maybeToken ->
            case maybeToken of
                Just token ->
                    ( { model | auth = LoggedIn token, loadState = LoadingFiles }
                    , listFilesCmd model token.value
                    )

                Nothing ->
                    ( model, Cmd.none )

        ClickedLogout ->
            ( { model | auth = LoggedOut "" False, files = [], remoteSnapshots = Dict.empty, selectedPath = Nothing, editorContent = "" }
            , clearToken ()
            )

        ClickedRefreshFiles ->
            case model.auth of
                LoggedIn token ->
                    ( { model | loadState = LoadingFiles }
                    , listFilesCmd model token.value
                    )

                LoggedOut _ _ ->
                    ( model, Cmd.none )

        FilesListed result ->
            case result of
                Ok files ->
                    let
                        nextModel =
                            { model
                                | files = List.sortBy .path files
                                , drafts = refreshDraftShas files model.drafts
                                , loadState = Working
                            }
                    in
                    ( nextModel, saveWorkspaceCmd nextModel )

                Err err ->
                    ( { model | loadState = Failed err }, Cmd.none )

        ClickedFile path ->
            case model.auth of
                LoggedIn token ->
                    ( { model | selectedPath = Just path, loadState = LoadingFile path, activePanel = EditorPanel }
                    , fetchFile
                        { token = token.value
                        , owner = model.config.admin.owner
                        , repo = model.config.admin.repo
                        , branch = model.config.admin.branch
                        , path = path
                        }
                    )

                LoggedOut _ _ ->
                    ( model, Cmd.none )

        FileLoaded result ->
            case result of
                Ok { meta, content } ->
                    let
                        existing =
                            Dict.get meta.path model.drafts

                        remote =
                            { path = meta.path
                            , sha = meta.sha
                            , contentHash = contentHash content
                            , content = content
                            }

                        ( draft, snapshots ) =
                            case existing of
                                Just saved ->
                                    let
                                        dirty =
                                            contentHash saved.content /= saved.baseContentHash

                                        remoteChanged =
                                            saved.baseSha /= meta.sha
                                    in
                                    if dirty && remoteChanged then
                                        ( { saved | conflict = True }
                                        , Dict.insert meta.path remote model.remoteSnapshots
                                        )

                                    else if dirty then
                                        ( { saved | baseSha = meta.sha, baseContentHash = remote.contentHash, conflict = False }
                                        , Dict.remove meta.path model.remoteSnapshots
                                        )

                                    else
                                        ( { saved | baseSha = meta.sha, baseContentHash = remote.contentHash, content = content, conflict = False }
                                        , Dict.remove meta.path model.remoteSnapshots
                                        )

                                Nothing ->
                                    ( { path = meta.path
                                      , baseSha = meta.sha
                                      , baseContentHash = remote.contentHash
                                      , content = content
                                      , staged = False
                                      , conflict = False
                                      }
                                    , Dict.remove meta.path model.remoteSnapshots
                                    )

                        nextModel =
                            { model
                                | files = upsertFile meta model.files
                                , drafts = Dict.insert meta.path draft model.drafts
                                , remoteSnapshots = snapshots
                                , selectedPath = Just meta.path
                                , editorContent = draft.content
                                , loadState = Working
                            }
                    in
                    ( nextModel
                    , Cmd.batch
                        [ mountEditor ()
                        , setEditorContent draft.content
                        , saveWorkspaceCmd nextModel
                        ]
                    )

                Err err ->
                    ( { model | loadState = Failed err }, Cmd.none )

        EditorChanged content ->
            case model.selectedPath of
                Just path ->
                    let
                        nextModel =
                            { model
                                | editorContent = content
                                , drafts = Dict.update path (Maybe.map (\draft -> { draft | content = content })) model.drafts
                            }
                    in
                    ( nextModel, saveWorkspaceCmd nextModel )

                Nothing ->
                    ( model, Cmd.none )

        WorkspaceLoaded drafts ->
            ( { model | drafts = drafts |> List.map (\draft -> ( draft.path, draft )) |> Dict.fromList }, Cmd.none )

        ToggledStage path ->
            let
                nextModel =
                    { model
                        | drafts =
                            Dict.update
                                path
                                (Maybe.map (\draft -> { draft | staged = not draft.staged }))
                                model.drafts
                    }
            in
            ( nextModel, saveWorkspaceCmd nextModel )

        CommitMessageChanged message ->
            ( { model | commitMessage = message }, Cmd.none )

        ClickedCommit ->
            case model.auth of
                LoggedIn token ->
                    let
                        staged =
                            stagedDrafts model

                        conflictPaths =
                            staged
                                |> List.filter .conflict
                                |> List.map .path
                    in
                    if List.isEmpty staged then
                        ( { model | commitState = CommitFailed "Stage at least one file before committing." }, Cmd.none )

                    else if not (List.isEmpty conflictPaths) then
                        ( { model | commitState = CommitConflicts conflictPaths }, Cmd.none )

                    else if String.isEmpty (String.trim model.commitMessage) then
                        ( { model | commitState = CommitFailed "Commit message is required." }, Cmd.none )

                    else
                        ( { model | commitState = CommitRunning }
                        , commitStaged
                            { token = token.value
                            , owner = model.config.admin.owner
                            , repo = model.config.admin.repo
                            , branch = model.config.admin.branch
                            , message = model.commitMessage
                            , files =
                                staged
                                    |> List.map
                                        (\draft ->
                                            { path = draft.path
                                            , content = draft.content
                                            , expectedSha = draft.baseSha
                                            }
                                        )
                            }
                        )

                LoggedOut _ _ ->
                    ( model, Cmd.none )

        CommitReturned result ->
            case result of
                CommitOk sha ->
                    let
                        nextDrafts =
                            model.drafts
                                |> Dict.map
                                    (\_ draft ->
                                        if draft.staged then
                                            { draft | staged = False, baseSha = "", baseContentHash = contentHash draft.content, conflict = False }

                                        else
                                            draft
                                    )

                        nextModel =
                            { model | drafts = nextDrafts, commitState = CommitSuccess sha }

                        refreshCmd =
                            case model.auth of
                                LoggedIn token ->
                                    listFilesCmd model token.value

                                LoggedOut _ _ ->
                                    Cmd.none
                    in
                    ( nextModel, Cmd.batch [ saveWorkspaceCmd nextModel, refreshCmd ] )

                CommitError err ->
                    ( { model | commitState = CommitFailed err }, Cmd.none )

                CommitConflictPaths paths ->
                    let
                        nextModel =
                            { model
                                | drafts =
                                    model.drafts
                                        |> Dict.map
                                            (\path draft ->
                                                if List.member path paths then
                                                    { draft | conflict = True }

                                                else
                                                    draft
                                            )
                                , commitState = CommitConflicts paths
                            }
                    in
                    ( nextModel, saveWorkspaceCmd nextModel )

        NewFilePathChanged path ->
            ( { model | newFilePath = path }, Cmd.none )

        ClickedCreateFile ->
            let
                pathResult =
                    normalizeNewPath model.config.admin model.newFilePath
            in
            case pathResult of
                Err err ->
                    ( { model | commitState = CommitFailed err }, Cmd.none )

                Ok path ->
                    if List.any (\file -> file.path == path) model.files then
                        ( { model | commitState = CommitFailed ("File already exists: " ++ path) }, Cmd.none )

                    else
                        let
                            content =
                                "---\ntitle: \"New Page\"\ndescription: \"\"\nslug: " ++ slugFromPath path ++ "\npublished: false\nnav: false\n---\n\n# New Page\n"

                            meta =
                                { path = path, name = fileName path, sha = "" }

                            draft =
                                { path = path
                                , baseSha = ""
                                , baseContentHash = ""
                                , content = content
                                , staged = True
                                , conflict = False
                                }

                            nextModel =
                                { model
                                    | files = upsertFile meta model.files
                                    , drafts = Dict.insert path draft model.drafts
                                    , remoteSnapshots = Dict.remove path model.remoteSnapshots
                                    , selectedPath = Just path
                                    , editorContent = content
                                    , newFilePath = ""
                                    , activePanel = EditorPanel
                                    , commitState = CommitIdle
                                }
                        in
                        ( nextModel
                        , Cmd.batch
                            [ mountEditor ()
                            , setEditorContent content
                            , saveWorkspaceCmd nextModel
                            ]
                        )

        ClickedDiscardLocal path ->
            case Dict.get path model.remoteSnapshots of
                Just remote ->
                    let
                        draft =
                            { path = path
                            , baseSha = remote.sha
                            , baseContentHash = remote.contentHash
                            , content = remote.content
                            , staged = False
                            , conflict = False
                            }

                        nextModel =
                            { model
                                | drafts = Dict.insert path draft model.drafts
                                , remoteSnapshots = Dict.remove path model.remoteSnapshots
                                , editorContent =
                                    if model.selectedPath == Just path then
                                        remote.content

                                    else
                                        model.editorContent
                                , commitState = CommitIdle
                            }

                        editorCmd =
                            if model.selectedPath == Just path then
                                setEditorContent remote.content

                            else
                                Cmd.none
                    in
                    ( nextModel, Cmd.batch [ editorCmd, saveWorkspaceCmd nextModel ] )

                Nothing ->
                    ( { model | commitState = CommitFailed ("Reload " ++ path ++ " before resolving this conflict.") }, Cmd.none )

        ClickedKeepLocal path ->
            case Dict.get path model.remoteSnapshots of
                Just remote ->
                    let
                        nextModel =
                            { model
                                | drafts =
                                    Dict.update
                                        path
                                        (Maybe.map
                                            (\draft ->
                                                { draft
                                                    | baseSha = remote.sha
                                                    , baseContentHash = remote.contentHash
                                                    , conflict = False
                                                }
                                            )
                                        )
                                        model.drafts
                                , remoteSnapshots = Dict.remove path model.remoteSnapshots
                                , commitState = CommitIdle
                            }
                    in
                    ( nextModel, saveWorkspaceCmd nextModel )

                Nothing ->
                    ( { model | commitState = CommitFailed ("Reload " ++ path ++ " before resolving this conflict.") }, Cmd.none )

        SwitchedPanel panel ->
            ( { model | activePanel = panel }, Cmd.none )

        SelectedComponent tag ->
            case Catalog.find tag of
                Just spec ->
                    ( { model
                        | builder =
                            { selectedTag = tag
                            , values = Catalog.initialValues spec
                            , body = Maybe.withDefault "" spec.body
                            }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        BuilderAttrChanged name value ->
            ( { model | builder = updateBuilderValues name value model.builder }, Cmd.none )

        BuilderBodyChanged value ->
            ( { model | builder = { body = value, selectedTag = model.builder.selectedTag, values = model.builder.values } }, Cmd.none )

        InsertedComponent ->
            case Catalog.find model.builder.selectedTag of
                Just spec ->
                    ( model, insertSnippet (Catalog.snippet spec model.builder.values model.builder.body) )

                Nothing ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div [ Attr.class "min-h-screen bg-bg-subtle text-text-primary" ]
        [ viewNav model
        , if not model.config.admin.enabled then
            viewDisabled

          else
            case model.auth of
                LoggedOut token remember ->
                    viewLogin token remember

                LoggedIn _ ->
                    viewWorkspace model
        ]


viewNav : Model -> Html Msg
viewNav model =
    Html.nav [ Attr.class "bg-brand text-text-on-dark" ]
        [ Html.div [ Attr.class "mx-auto flex max-w-5xl items-center justify-between px-4 py-3" ]
            [ Html.a [ Attr.href "/", Attr.class "rounded focus-visible:ring-2 focus-visible:ring-brand-yellow" ]
                [ Html.img [ Attr.src model.config.logo, Attr.alt model.config.logoAlt, Attr.class "h-12" ] [] ]
            , Html.div [ Attr.class "flex items-center gap-4" ]
                [ Html.span [ Attr.class "type-caption text-white/80" ] [ Html.text "Admin" ]
                , case model.auth of
                    LoggedIn _ ->
                        Html.button [ Events.onClick ClickedLogout, Attr.class "type-caption underline hover:text-brand-yellow focus-visible:ring-2 focus-visible:ring-brand-yellow" ] [ Html.text "Log out" ]

                    LoggedOut _ _ ->
                        Html.text ""
                ]
            ]
        ]


viewDisabled : Html Msg
viewDisabled =
    Html.main_ [ Attr.class "mx-auto max-w-xl px-4 py-12" ]
        [ viewCard
            [ Html.h1 [ Attr.class "type-h2 mb-3" ] [ Html.text "Admin is disabled" ]
            , Html.p [ Attr.class "type-body text-text-muted" ] [ Html.text "Enable [admin] in content/config.toml to publish the editor." ]
            ]
        ]


viewLogin : String -> Bool -> Html Msg
viewLogin token remember =
    Html.main_ [ Attr.class "mx-auto max-w-xl px-4 py-12" ]
        [ viewCard
            [ Html.h1 [ Attr.class "type-h2 mb-3" ] [ Html.text "Content admin" ]
            , Html.p [ Attr.class "type-body mb-6 text-text-muted" ] [ Html.text "Paste a GitHub Personal Access Token with access to the configured content repository." ]
            , Html.form [ Events.onSubmit SubmittedToken, Attr.class "space-y-4" ]
                [ Html.input
                    [ Attr.type_ "password"
                    , Attr.value token
                    , Attr.placeholder "github_pat_..."
                    , Events.onInput TokenInputChanged
                    , Attr.class inputClass
                    ]
                    []
                , Html.label [ Attr.class "flex items-center gap-3 type-caption text-text-muted" ]
                    [ Html.input [ Attr.type_ "checkbox", Attr.checked remember, Events.onCheck RememberChanged, Attr.class "h-4 w-4" ] []
                    , Html.span [] [ Html.text "Remember this browser" ]
                    ]
                , Html.button [ Attr.type_ "submit", Attr.class primaryButtonClass ] [ Html.text "Log in" ]
                ]
            ]
        ]


viewWorkspace : Model -> Html Msg
viewWorkspace model =
    Html.main_ [ Attr.class "mx-auto grid max-w-7xl gap-4 px-4 py-6 lg:grid-cols-[18rem_minmax(0,1fr)_20rem]" ]
        [ Html.div [ Attr.class "lg:hidden" ] [ viewTabs model.activePanel ]
        , Html.aside [ panelClass FilesPanel model.activePanel "lg:block" ] [ viewFiles model ]
        , Html.section [ centerPanelClass model.activePanel ] [ viewEditorAndPreview model ]
        , Html.aside [ panelClass ComponentsPanel model.activePanel "lg:block" ] [ viewComponents model ]
        ]


viewTabs : ActivePanel -> Html Msg
viewTabs active =
    Html.div [ Attr.class "grid grid-cols-4 gap-2" ]
        [ tabButton FilesPanel active "Files"
        , tabButton EditorPanel active "Editor"
        , tabButton PreviewPanel active "Preview"
        , tabButton ComponentsPanel active "Components"
        ]


viewFiles : Model -> Html Msg
viewFiles model =
    viewCard
        [ Html.div [ Attr.class "mb-4 flex items-center justify-between gap-3" ]
            [ Html.div []
                [ Html.h2 [ Attr.class "type-h4" ] [ Html.text "Files" ]
                , Html.p [ Attr.class "type-caption text-text-muted" ] [ Html.text (repoLabel model.config.admin) ]
                ]
            , Html.button [ Events.onClick ClickedRefreshFiles, Attr.class smallButtonClass ] [ Html.text "Refresh" ]
            ]
        , Html.div [ Attr.class "mb-4 space-y-2" ]
            [ Html.input [ Attr.value model.newFilePath, Events.onInput NewFilePathChanged, Attr.placeholder "new-page.md", Attr.class inputClass ] []
            , viewContentPathHint model.config.admin
            , Html.button [ Events.onClick ClickedCreateFile, Attr.class secondaryButtonClass ] [ Html.text "Create Markdown file" ]
            ]
        , viewLoadState model.loadState
        , Html.ul [ Attr.class "max-h-[60vh] space-y-1 overflow-auto" ] (List.map (viewFileItem model) model.files)
        , viewCommitBox model
        ]


viewFileItem : Model -> FileMeta -> Html Msg
viewFileItem model file =
    let
        draft =
            Dict.get file.path model.drafts

        dirty =
            draft |> Maybe.map (\d -> contentHash d.content /= d.baseContentHash) |> Maybe.withDefault False

        staged =
            draft |> Maybe.map .staged |> Maybe.withDefault False

        conflict =
            draft |> Maybe.map .conflict |> Maybe.withDefault False
    in
    Html.li [ Attr.class "rounded-lg border border-border-default bg-bg-page" ]
        [ Html.button
            [ Events.onClick (ClickedFile file.path)
            , Attr.class
                ("block min-h-11 w-full rounded-lg px-3 py-2 text-left type-caption hover:bg-bg-subtle focus-visible:ring-2 focus-visible:ring-brand "
                    ++ (if model.selectedPath == Just file.path then
                            "bg-brand text-text-on-dark"

                        else
                            ""
                       )
                )
            ]
            [ Html.div [ Attr.class "font-semibold" ] [ Html.text file.name ]
            , Html.div [ Attr.class "break-all opacity-70" ] [ Html.text file.path ]
            , Html.div [ Attr.class "mt-1 flex gap-2" ]
                [ statusPill dirty "dirty"
                , statusPill staged "staged"
                , statusPill conflict "conflict"
                ]
            ]
        ]


viewEditorAndPreview : Model -> Html Msg
viewEditorAndPreview model =
    let
        selectedDraft =
            model.selectedPath |> Maybe.andThen (\path -> Dict.get path model.drafts)
    in
    Html.div [ Attr.class "grid gap-4 lg:grid-cols-2" ]
        [ Html.div [ panelClass EditorPanel model.activePanel "lg:block" ]
            [ viewCard
                [ Html.div [ Attr.class "mb-3 flex items-center justify-between gap-3" ]
                    [ Html.h2 [ Attr.class "type-h4" ] [ Html.text (Maybe.withDefault "Select a file" model.selectedPath) ]
                    , case selectedDraft of
                        Just draft ->
                            Html.button [ Events.onClick (ToggledStage draft.path), Attr.class secondaryButtonClass ]
                                [ Html.text
                                    (if draft.staged then
                                        "Unstage"

                                     else
                                        "Stage"
                                    )
                                ]

                        Nothing ->
                            Html.text ""
                    ]
                , viewConflictActions model selectedDraft
                , Html.div [ Attr.id "cm-editor", Attr.class "min-h-[60vh] overflow-hidden rounded-lg border border-border-default" ] []
                ]
            ]
        , Html.div [ panelClass PreviewPanel model.activePanel "lg:block" ]
            [ viewCard
                [ Html.div [ Attr.class "mb-3" ]
                    [ Html.h2 [ Attr.class "type-h4" ] [ Html.text "Live preview" ]
                    , Html.p [ Attr.class "type-caption text-text-muted" ] [ Html.text "Rendered with the same MarkdownRenderer used by the public site." ]
                    ]
                , Html.div [ Attr.class "rounded-lg border border-border-default bg-bg-page p-4" ]
                    [ MarkdownRenderer.renderMarkdown
                        { childPages = []
                        , sectionSlug = Nothing
                        }
                        (markdownBody model.editorContent)
                    ]
                ]
            ]
        ]


viewComponents : Model -> Html Msg
viewComponents model =
    let
        selectedSpec =
            Catalog.find model.builder.selectedTag
                |> Maybe.withDefault (List.head Catalog.all |> Maybe.withDefault { tag = "callout", label = "Callout", description = "", attributes = [], body = Just "" })
    in
    viewCard
        [ Html.h2 [ Attr.class "type-h4 mb-2" ] [ Html.text "Component builder" ]
        , Html.p [ Attr.class "type-caption mb-4 text-text-muted" ] [ Html.text "Choose a component, fill the fields, and insert a Markdown tag at the editor cursor." ]
        , Html.select [ Attr.value selectedSpec.tag, Events.onInput SelectedComponent, Attr.class inputClass ]
            (Catalog.all |> List.map (\spec -> Html.option [ Attr.value spec.tag ] [ Html.text spec.label ]))
        , Html.p [ Attr.class "type-caption my-3 text-text-muted" ] [ Html.text selectedSpec.description ]
        , Html.div [ Attr.class "space-y-3" ]
            (selectedSpec.attributes |> List.map (viewAttributeField model.builder))
        , case selectedSpec.body of
            Just _ ->
                Html.textarea
                    [ Attr.value model.builder.body
                    , Events.onInput BuilderBodyChanged
                    , Attr.class (inputClass ++ " mt-3 min-h-32")
                    ]
                    []

            Nothing ->
                Html.text ""
        , Html.button
            [ Events.onClick InsertedComponent
            , Attr.disabled (model.selectedPath == Nothing)
            , Attr.class (buttonClass primaryButtonClass (model.selectedPath == Nothing) ++ " mt-4 w-full")
            ]
            [ Html.text "Insert component" ]
        ]


viewAttributeField : BuilderState -> Catalog.AttributeField -> Html Msg
viewAttributeField builder field =
    Html.label [ Attr.class "block" ]
        [ Html.span [ Attr.class "type-caption mb-1 block text-text-muted" ] [ Html.text field.label ]
        , Html.input
            [ Attr.value (Dict.get field.name builder.values |> Maybe.withDefault field.default)
            , Events.onInput (BuilderAttrChanged field.name)
            , Attr.class inputClass
            ]
            []
        ]


viewCommitBox : Model -> Html Msg
viewCommitBox model =
    let
        staged =
            stagedDrafts model

        hasConflict =
            List.any .conflict staged

        disabled =
            List.isEmpty staged || hasConflict || model.commitState == CommitRunning
    in
    Html.div [ Attr.class "mt-6 border-t border-border-default pt-4" ]
        [ Html.h3 [ Attr.class "type-h4 mb-2" ] [ Html.text "Staged changes" ]
        , Html.p [ Attr.class "type-caption mb-3 text-text-muted" ] [ Html.text (String.fromInt (List.length staged) ++ " files staged") ]
        , Html.input [ Attr.value model.commitMessage, Events.onInput CommitMessageChanged, Attr.class inputClass ] []
        , Html.button [ Events.onClick ClickedCommit, Attr.disabled disabled, Attr.class (buttonClass primaryButtonClass disabled ++ " mt-3 w-full") ]
            [ Html.text
                (if model.commitState == CommitRunning then
                    "Pushing..."

                 else
                    "Commit & push"
                )
            ]
        , viewCommitState model.commitState
        ]


viewContentPathHint : AdminConfig -> Html Msg
viewContentPathHint config =
    let
        prefix =
            normalizePrefix config.contentPath
    in
    if String.isEmpty prefix then
        Html.text ""

    else
        Html.p [ Attr.class "type-caption text-text-muted" ] [ Html.text ("New files are created under " ++ prefix) ]


viewConflictActions : Model -> Maybe Draft -> Html Msg
viewConflictActions model maybeDraft =
    case maybeDraft of
        Just draft ->
            if draft.conflict then
                let
                    hasSnapshot =
                        Dict.member draft.path model.remoteSnapshots
                in
                Html.div [ Attr.class "mb-3 rounded-lg border border-brand-red bg-bg-subtle p-3" ]
                    [ Html.p [ Attr.class "type-caption mb-3 text-brand-red" ] [ Html.text "Remote content changed before this draft could be committed." ]
                    , if hasSnapshot then
                        Html.text ""

                      else
                        Html.p [ Attr.class "type-caption mb-3 text-text-muted" ] [ Html.text "Reload this file before choosing how to resolve it." ]
                    , Html.div [ Attr.class "flex flex-wrap gap-2" ]
                        [ Html.button
                            [ Events.onClick (ClickedDiscardLocal draft.path)
                            , Attr.disabled (not hasSnapshot)
                            , Attr.class (buttonClass secondaryButtonClass (not hasSnapshot))
                            ]
                            [ Html.text "Discard local/reload remote" ]
                        , Html.button
                            [ Events.onClick (ClickedKeepLocal draft.path)
                            , Attr.disabled (not hasSnapshot)
                            , Attr.class (buttonClass secondaryButtonClass (not hasSnapshot))
                            ]
                            [ Html.text "Keep local on latest base" ]
                        ]
                    ]

            else
                Html.text ""

        Nothing ->
            Html.text ""


viewCommitState : CommitState -> Html Msg
viewCommitState state =
    case state of
        CommitIdle ->
            Html.text ""

        CommitRunning ->
            Html.p [ Attr.class "type-caption mt-2 text-text-muted" ] [ Html.text "Creating one multi-file commit..." ]

        CommitSuccess sha ->
            Html.p [ Attr.class "type-caption mt-2 text-green-700" ] [ Html.text ("Pushed " ++ String.left 8 sha) ]

        CommitFailed err ->
            Html.p [ Attr.class "type-caption mt-2 text-brand-red" ] [ Html.text err ]

        CommitConflicts paths ->
            Html.p [ Attr.class "type-caption mt-2 text-brand-red" ] [ Html.text ("Remote changed before push: " ++ String.join ", " paths) ]


viewLoadState : LoadState -> Html Msg
viewLoadState state =
    case state of
        LoadingFiles ->
            Html.p [ Attr.class "type-caption mb-3 text-text-muted" ] [ Html.text "Loading files..." ]

        LoadingFile path ->
            Html.p [ Attr.class "type-caption mb-3 text-text-muted" ] [ Html.text ("Loading " ++ path ++ "...") ]

        Failed err ->
            Html.p [ Attr.class "type-caption mb-3 text-brand-red" ] [ Html.text err ]

        _ ->
            Html.text ""


viewCard : List (Html Msg) -> Html Msg
viewCard children =
    Html.div [ Attr.class "rounded-xl border border-border-default bg-bg-page p-5 shadow-sm" ] children


tabButton : ActivePanel -> ActivePanel -> String -> Html Msg
tabButton panel active label =
    Html.button
        [ Events.onClick (SwitchedPanel panel)
        , Attr.class
            ("min-h-11 rounded-lg px-3 py-2 type-body-small focus-visible:ring-2 focus-visible:ring-brand "
                ++ (if panel == active then
                        "bg-brand text-text-on-dark"

                    else
                        "border border-border-default bg-bg-page text-text-primary"
                   )
            )
        ]
        [ Html.text label ]


statusPill : Bool -> String -> Html Msg
statusPill visible label =
    if visible then
        Html.span [ Attr.class "rounded-full bg-brand-yellow px-2 py-0.5 text-[0.7rem] text-brand" ] [ Html.text label ]

    else
        Html.text ""


panelClass : ActivePanel -> ActivePanel -> String -> Html.Attribute msg
panelClass panel active desktopClass =
    Attr.class
        (if panel == active then
            desktopClass

         else
            "hidden " ++ desktopClass
        )


centerPanelClass : ActivePanel -> Html.Attribute msg
centerPanelClass active =
    Attr.class
        (case active of
            EditorPanel ->
                "block"

            PreviewPanel ->
                "block"

            _ ->
                "hidden lg:block"
        )


primaryButtonClass : String
primaryButtonClass =
    "inline-flex min-h-11 items-center justify-center rounded-lg bg-brand-yellow px-4 py-2 type-body-small text-brand hover:bg-brand hover:text-brand-yellow focus-visible:ring-2 focus-visible:ring-brand"


secondaryButtonClass : String
secondaryButtonClass =
    "inline-flex min-h-11 items-center justify-center rounded-lg border border-border-brand bg-bg-page px-4 py-2 type-body-small text-brand hover:bg-bg-subtle focus-visible:ring-2 focus-visible:ring-brand"


smallButtonClass : String
smallButtonClass =
    "inline-flex min-h-11 items-center justify-center rounded-lg border border-border-default px-3 py-2 type-caption hover:bg-bg-subtle focus-visible:ring-2 focus-visible:ring-brand"


buttonClass : String -> Bool -> String
buttonClass base disabled =
    if disabled then
        base ++ " cursor-not-allowed opacity-50"

    else
        base


inputClass : String
inputClass =
    "w-full rounded-lg border border-border-default bg-bg-page px-3 py-2 type-caption text-text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-brand"


listFilesCmd : Model -> String -> Cmd Msg
listFilesCmd model token =
    listFiles
        { token = token
        , owner = model.config.admin.owner
        , repo = model.config.admin.repo
        , branch = model.config.admin.branch
        , contentPath = model.config.admin.contentPath
        }


saveWorkspaceCmd : Model -> Cmd Msg
saveWorkspaceCmd model =
    saveWorkspace { key = workspaceKey model.config, drafts = Dict.values model.drafts }


stagedDrafts : Model -> List Draft
stagedDrafts model =
    model.drafts
        |> Dict.values
        |> List.filter .staged


upsertFile : FileMeta -> List FileMeta -> List FileMeta
upsertFile meta files =
    meta :: List.filter (\file -> file.path /= meta.path) files


refreshDraftShas : List FileMeta -> Dict String Draft -> Dict String Draft
refreshDraftShas files drafts =
    List.foldl
        (\file acc ->
            Dict.update
                file.path
                (Maybe.map
                    (\draft ->
                        if String.isEmpty draft.baseSha then
                            if contentHash draft.content == draft.baseContentHash then
                                { draft | baseSha = file.sha, conflict = False }

                            else
                                { draft | conflict = True }

                        else if draft.baseSha /= file.sha then
                            { draft | conflict = True }

                        else
                            draft
                    )
                )
                acc
        )
        drafts
        files


updateBuilderValues : String -> String -> BuilderState -> BuilderState
updateBuilderValues name value builder =
    { builder | values = Dict.insert name value builder.values }


markdownBody : String -> String
markdownBody content =
    if String.startsWith "---\n" content then
        case String.indexes "\n---\n" content of
            _ :: closing :: _ ->
                String.dropLeft (closing + 5) content

            _ ->
                content

    else
        content


contentHash : String -> String
contentHash content =
    String.fromInt (String.length content) ++ ":" ++ String.left 24 content


repoLabel : AdminConfig -> String
repoLabel config =
    config.owner ++ "/" ++ config.repo ++ "@" ++ config.branch


workspaceKey : SiteConfig -> String
workspaceKey config =
    "admin-workspace:" ++ config.admin.owner ++ "/" ++ config.admin.repo ++ ":" ++ config.admin.branch ++ ":" ++ config.admin.contentPath


normalizeNewPath : AdminConfig -> String -> Result String String
normalizeNewPath config raw =
    let
        trimmed =
            String.trim raw

        withoutSlashes =
            trimmed
                |> String.replace "\\" "/"
                |> String.split "/"
                |> List.filter (\part -> not (String.isEmpty part))
                |> String.join "/"

        withExtension =
            if String.isEmpty withoutSlashes || String.endsWith ".md" withoutSlashes then
                withoutSlashes

            else
                withoutSlashes ++ ".md"

        prefix =
            normalizePrefix config.contentPath

        prefixed =
            if String.isEmpty prefix || String.startsWith prefix withExtension then
                withExtension

            else
                prefix ++ withExtension

        invalidParts =
            prefixed
                |> String.split "/"
                |> List.any (\part -> part == "." || part == "..")
    in
    if String.isEmpty withExtension then
        Err "Enter a Markdown file path."

    else if invalidParts || String.startsWith "/" trimmed then
        Err "Use a relative Markdown path without . or .. segments."

    else
        Ok prefixed


normalizePrefix : String -> String
normalizePrefix raw =
    let
        trimmed =
            raw
                |> String.trim
                |> String.replace "\\" "/"
                |> String.split "/"
                |> List.filter (\part -> not (String.isEmpty part))
                |> String.join "/"
    in
    if String.isEmpty trimmed then
        ""

    else
        trimmed ++ "/"


slugFromPath : String -> String
slugFromPath path =
    path
        |> String.split "/"
        |> List.reverse
        |> List.head
        |> Maybe.withDefault "new-page"
        |> String.replace ".md" ""


fileName : String -> String
fileName path =
    path
        |> String.split "/"
        |> List.reverse
        |> List.head
        |> Maybe.withDefault path


siteConfigFromFlags : Decode.Value -> SiteConfig
siteConfigFromFlags flags =
    let
        owner =
            stringAt [ "admin", "content_owner" ] (stringAt [ "contentOwner" ] (stringAt [ "owner" ] "" flags) flags) flags

        repo =
            stringAt [ "admin", "content_repo" ] (stringAt [ "contentRepo" ] (stringAt [ "repo" ] "" flags) flags) flags
    in
    { title = stringAt [ "site", "title" ] "Suomen Palikkaharrastajat ry" flags
    , logo = stringAt [ "branding", "logo_dark" ] "/logo/horizontal/svg/horizontal-full-dark.svg" flags
    , logoAlt = stringAt [ "branding", "logo_alt" ] "Suomen Palikkaharrastajat ry" flags
    , admin =
        { enabled = boolAt [ "admin", "enabled" ] False flags
        , path = stringAt [ "admin", "path" ] "/admin/" flags
        , owner = owner
        , repo = repo
        , branch = stringAt [ "admin", "content_branch" ] "main" flags
        , contentPath = stringAt [ "admin", "content_path" ] "" flags
        }
    }


stringAt : List String -> String -> Decode.Value -> String
stringAt path fallback value =
    Decode.decodeValue (fieldPath path Decode.string) value
        |> Result.withDefault fallback


boolAt : List String -> Bool -> Decode.Value -> Bool
boolAt path fallback value =
    Decode.decodeValue (fieldPath path Decode.bool) value
        |> Result.withDefault fallback


fieldPath : List String -> Decoder a -> Decoder a
fieldPath path decoder =
    List.foldr Decode.field decoder path


decodeTokenLoaded : Decode.Value -> Maybe Token
decodeTokenLoaded value =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.null Nothing
            , Decode.map2 (\token remember -> Just { value = token, remember = remember })
                (Decode.field "token" Decode.string)
                (Decode.field "remember" Decode.bool)
            ]
        )
        value
        |> Result.withDefault Nothing


decodeFilesListed : Decode.Value -> Result String (List FileMeta)
decodeFilesListed value =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.field "error" Decode.string |> Decode.map Err
            , Decode.field "files" (Decode.list fileMetaDecoder) |> Decode.map Ok
            ]
        )
        value
        |> Result.withDefault (Err "Could not decode file list.")


decodeFileLoaded : Decode.Value -> Result String { meta : FileMeta, content : String }
decodeFileLoaded value =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.field "error" Decode.string |> Decode.map Err
            , Decode.map2 (\meta content -> Ok { meta = meta, content = content })
                (Decode.field "meta" fileMetaDecoder)
                (Decode.field "content" Decode.string)
            ]
        )
        value
        |> Result.withDefault (Err "Could not decode file.")


fileMetaDecoder : Decoder FileMeta
fileMetaDecoder =
    Decode.map3 FileMeta
        (Decode.field "path" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "sha" Decode.string)


draftDecoder : Decoder Draft
draftDecoder =
    Decode.map6 Draft
        (Decode.field "path" Decode.string)
        (Decode.field "baseSha" Decode.string)
        (Decode.field "baseContentHash" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "staged" Decode.bool)
        (Decode.field "conflict" Decode.bool)


decodeWorkspace : Decode.Value -> List Draft
decodeWorkspace value =
    Decode.decodeValue (Decode.list draftDecoder) value
        |> Result.withDefault []


decodeCommitResult : Decode.Value -> CommitResult
decodeCommitResult value =
    Decode.decodeValue
        (Decode.oneOf
            [ Decode.field "sha" Decode.string |> Decode.map CommitOk
            , Decode.field "conflicts" (Decode.list Decode.string) |> Decode.map CommitConflictPaths
            , Decode.field "error" Decode.string |> Decode.map CommitError
            ]
        )
        value
        |> Result.withDefault (CommitError "Could not decode commit result.")


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ tokenLoaded (decodeTokenLoaded >> TokenLoaded)
        , filesListed (decodeFilesListed >> FilesListed)
        , fileLoaded (decodeFileLoaded >> FileLoaded)
        , editorContentChanged EditorChanged
        , workspaceLoaded (decodeWorkspace >> WorkspaceLoaded)
        , commitDone (decodeCommitResult >> CommitReturned)
        ]


port loadToken : () -> Cmd msg


port storeToken : { token : String, remember : Bool } -> Cmd msg


port clearToken : () -> Cmd msg


port tokenLoaded : (Decode.Value -> msg) -> Sub msg


port listFiles : { token : String, owner : String, repo : String, branch : String, contentPath : String } -> Cmd msg


port filesListed : (Decode.Value -> msg) -> Sub msg


port fetchFile : { token : String, owner : String, repo : String, branch : String, path : String } -> Cmd msg


port fileLoaded : (Decode.Value -> msg) -> Sub msg


port mountEditor : () -> Cmd msg


port setEditorContent : String -> Cmd msg


port insertSnippet : String -> Cmd msg


port editorContentChanged : (String -> msg) -> Sub msg


port loadWorkspace : String -> Cmd msg


port saveWorkspace : { key : String, drafts : List Draft } -> Cmd msg


port workspaceLoaded : (Decode.Value -> msg) -> Sub msg


port commitStaged :
    { token : String
    , owner : String
    , repo : String
    , branch : String
    , message : String
    , files : List { path : String, content : String, expectedSha : String }
    }
    -> Cmd msg


port commitDone : (Decode.Value -> msg) -> Sub msg
