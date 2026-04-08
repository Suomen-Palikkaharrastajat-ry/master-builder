module ContentMarkdown exposing (PageData, isPartialSlug, loadFrontmatter, loadPage)

{-| Utilities for loading markdown content with frontmatter and include expansion.
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Json.Decode as Decode
import Regex


{-| Data shape used by route modules after loading markdown content.
-}
type alias PageData =
    { frontmatter : Frontmatter
    , body : String
    }


loadPage : String -> String -> BackendTask FatalError PageData
loadPage contentRoot filePath =
    File.bodyWithFrontmatter
        (\body ->
            Frontmatter.decoder
                |> Decode.map (\fm -> { frontmatter = fm, body = body })
        )
        filePath
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\pageData ->
                expandIncludes
                    { contentRoot = contentRoot
                    , currentFile = filePath
                    , stack = [ filePath ]
                    }
                    pageData.body
                    |> BackendTask.map (\expandedBody -> { pageData | body = expandedBody })
            )


loadFrontmatter : String -> BackendTask FatalError Frontmatter
loadFrontmatter filePath =
    File.bodyWithFrontmatter (\_ -> Frontmatter.decoder) filePath
        |> BackendTask.allowFatal


isPartialSlug : String -> Bool
isPartialSlug slug =
    slug
        |> pathSegments
        |> List.reverse
        |> List.head
        |> Maybe.map (String.startsWith "_")
        |> Maybe.withDefault False


type alias ExpandContext =
    { contentRoot : String
    , currentFile : String
    , stack : List String
    }


type alias IncludeMatch =
    { index : Int
    , raw : String
    , src : String
    }


expandIncludes : ExpandContext -> String -> BackendTask FatalError String
expandIncludes ctx body =
    case findFirstInclude body of
        Nothing ->
            BackendTask.succeed body

        Just includeMatch ->
            case resolveIncludePath ctx.contentRoot ctx.currentFile includeMatch.src of
                Err pathError ->
                    includeErrorTask ctx.currentFile (pathError ++ " (src: " ++ includeMatch.src ++ ")")

                Ok includePath ->
                    if List.member includePath ctx.stack then
                        includeErrorTask includePath ("Include cycle detected: " ++ String.join " -> " (ctx.stack ++ [ includePath ]))

                    else
                        readIncludeFile includePath
                            |> BackendTask.andThen
                                (\includedContent ->
                                    expandIncludes
                                        { contentRoot = ctx.contentRoot
                                        , currentFile = includePath
                                        , stack = ctx.stack ++ [ includePath ]
                                        }
                                        includedContent
                                )
                            |> BackendTask.andThen
                                (\expandedInclude ->
                                    let
                                        before =
                                            String.left includeMatch.index body

                                        after =
                                            String.dropLeft (includeMatch.index + String.length includeMatch.raw) body
                                    in
                                    expandIncludes ctx (before ++ expandedInclude ++ after)
                                )


findFirstInclude : String -> Maybe IncludeMatch
findFirstInclude content =
    case Regex.fromString "<include\\s+src=\"([^\"]+)\"\\s*/>" of
        Nothing ->
            Nothing

        Just includeRegex ->
            case Regex.findAtMost 1 includeRegex content of
                match :: _ ->
                    case match.submatches of
                        (Just src) :: _ ->
                            Just
                                { index = match.index
                                , raw = match.match
                                , src = src
                                }

                        _ ->
                            Nothing

                [] ->
                    Nothing


resolveIncludePath : String -> String -> String -> Result String String
resolveIncludePath contentRoot currentFile src =
    if String.isEmpty src then
        Err "Include src is empty"

    else if String.startsWith "/" src then
        Err "Absolute include paths are not supported"

    else
        let
            baseSegments =
                dirname currentFile |> pathSegments

            rootSegments =
                pathSegments contentRoot

            srcSegments =
                pathSegments src
        in
        case applyRelativePath baseSegments srcSegments of
            Err err ->
                Err err

            Ok resolvedSegments ->
                if startsWithSegments rootSegments resolvedSegments then
                    Ok (String.join "/" resolvedSegments)

                else
                    Err "Include path resolves outside CONTENT_DIR"


applyRelativePath : List String -> List String -> Result String (List String)
applyRelativePath baseSegments srcSegments =
    List.foldl
        (\segment accResult ->
            accResult
                |> Result.andThen
                    (\acc ->
                        if segment == "." then
                            Ok acc

                        else if segment == ".." then
                            case List.reverse acc of
                                _ :: restRev ->
                                    Ok (List.reverse restRev)

                                [] ->
                                    Err "Include path traverses above project root"

                        else
                            Ok (acc ++ [ segment ])
                    )
        )
        (Ok baseSegments)
        srcSegments


pathSegments : String -> List String
pathSegments path =
    path
        |> String.split "/"
        |> List.filter (\segment -> segment /= "")


dirname : String -> String
dirname path =
    case List.reverse (pathSegments path) of
        _ :: restRev ->
            String.join "/" (List.reverse restRev)

        [] ->
            ""


startsWithSegments : List String -> List String -> Bool
startsWithSegments prefix value =
    case ( prefix, value ) of
        ( [], _ ) ->
            True

        ( _, [] ) ->
            False

        ( p :: ps, v :: vs ) ->
            p == v && startsWithSegments ps vs


readIncludeFile : String -> BackendTask FatalError String
readIncludeFile includePath =
    File.rawFile includePath
        |> BackendTask.onError
            (\_ ->
                includeErrorTask includePath ("Included file does not exist or cannot be read: " ++ includePath)
            )


includeErrorTask : String -> String -> BackendTask FatalError a
includeErrorTask filePath message =
    BackendTask.fail
        (FatalError.fromString
            ("Markdown include error in `" ++ filePath ++ "`\n\n" ++ message)
        )
