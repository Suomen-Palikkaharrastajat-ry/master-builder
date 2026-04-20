module ContentMarkdown exposing (PageData, TocNode, isPartialSlug, loadFrontmatter, loadPage, loadPageOrSectionIndex, loadSectionChildren, loadTocTree)

{-| Utilities for loading markdown content with frontmatter and include expansion.
-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Json.Decode as Decode
import Regex


{-| Data shape used by route modules after loading markdown content.

`pageDir` is the directory of the source file relative to the content root,
with a trailing slash (e.g. `"jasenpalvelut/"`) or `""` for root-level files.
It is used to resolve relative image paths in the markdown body.
-}
type alias PageData =
    { frontmatter : Frontmatter
    , body : String
    , pageDir : String
    , isIndex : Bool
    }


{-| A content node with its immediate section children, used to build the `<toc />` tree.
`sectionChildren` is the list of pages directly inside this item's directory slug.
For leaf pages and pages with no sub-directory, it is [].
-}
type alias TocNode =
    { slug : String
    , frontmatter : Frontmatter
    , sectionChildren : List { slug : String, frontmatter : Frontmatter }
    }


loadPage : String -> String -> BackendTask FatalError PageData
loadPage contentRoot filePath =
    File.bodyWithFrontmatter
        (\body ->
            Frontmatter.decoder
                |> Decode.map (\fm -> { frontmatter = fm, body = body, pageDir = pageDirFromPath contentRoot filePath, isIndex = False })
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


{-| Like loadPage, but tries `<slug>.md` first; if not found, falls back to `<slug>/index.md`.
Used so that Route/Slug\_ can serve both flat pages and section index pages.
-}
loadPageOrSectionIndex : String -> String -> BackendTask FatalError PageData
loadPageOrSectionIndex dir slug =
    let
        flatPath =
            dir ++ "/" ++ slug ++ ".md"

        indexPath =
            dir ++ "/" ++ slug ++ "/index.md"

        loadFrom filePath =
            File.bodyWithFrontmatter
                (\body ->
                    Frontmatter.decoder
                        |> Decode.map (\fm -> ( { frontmatter = fm, body = body, pageDir = pageDirFromPath dir filePath, isIndex = String.endsWith "/index.md" filePath }, filePath ))
                )
                filePath
    in
    loadFrom flatPath
        |> BackendTask.onError (\_ -> loadFrom indexPath)
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\( pageData, filePath ) ->
                expandIncludes
                    { contentRoot = dir
                    , currentFile = filePath
                    , stack = [ filePath ]
                    }
                    pageData.body
                    |> BackendTask.map (\expandedBody -> { pageData | body = expandedBody })
            )


{-| Load frontmatters of top-level pages for the root index `<toc />`.
Includes both flat pages (content/slug.md) and section indexes (content/section/index.md),
filtered by nav visibility, sorted by order.
-}
loadRootChildren : String -> BackendTask FatalError (List { slug : String, frontmatter : Frontmatter })
loadRootChildren dir =
    let
        flatPages =
            Glob.succeed identity
                |> Glob.match (Glob.literal (dir ++ "/"))
                |> Glob.capture Glob.wildcard
                |> Glob.match (Glob.literal ".md")
                |> Glob.toBackendTask
                |> BackendTask.andThen
                    (\slugs ->
                        slugs
                            |> List.filter (\s -> s /= "index" && not (isPartialSlug s))
                            |> List.map (\s -> loadFrontmatter (dir ++ "/" ++ s ++ ".md") |> BackendTask.map (\fm -> { slug = s, frontmatter = fm }))
                            |> BackendTask.combine
                    )

        sectionIndexes =
            Glob.succeed identity
                |> Glob.match (Glob.literal (dir ++ "/"))
                |> Glob.capture Glob.wildcard
                |> Glob.match (Glob.literal "/index.md")
                |> Glob.toBackendTask
                |> BackendTask.andThen
                    (\sections ->
                        sections
                            |> List.map (\s -> loadFrontmatter (dir ++ "/" ++ s ++ "/index.md") |> BackendTask.map (\fm -> { slug = s, frontmatter = fm }))
                            |> BackendTask.combine
                    )
    in
    BackendTask.map2 (++) flatPages sectionIndexes
        |> BackendTask.map (List.filter (.frontmatter >> .published) >> List.sortBy (.frontmatter >> .order))


{-| Load frontmatters of all non-index, non-partial pages inside a section directory,
sorted by their `order` field. Returns [] when the directory doesn't exist.
-}
loadSectionChildren : String -> String -> BackendTask FatalError (List { slug : String, frontmatter : Frontmatter })
loadSectionChildren dir section =
    Glob.succeed identity
        |> Glob.match (Glob.literal (dir ++ "/" ++ section ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (\slugs ->
                slugs
                    |> List.filter (\s -> s /= "index" && not (isPartialSlug s))
                    |> List.map (\s -> loadFrontmatter (dir ++ "/" ++ section ++ "/" ++ s ++ ".md") |> BackendTask.map (\fm -> { slug = s, frontmatter = fm }))
                    |> BackendTask.combine
            )
        |> BackendTask.map (List.filter (.frontmatter >> .published) >> List.sortBy (.frontmatter >> .order))


{-| Load a TocNode list for a given section (or "" for root).
Each node contains the page frontmatter and the frontmatters of its direct sub-pages.
Used to feed the `<toc />` tag with depth-aware data.
-}
loadTocTree : String -> String -> BackendTask FatalError (List TocNode)
loadTocTree dir section =
    let
        parentLoader =
            if String.isEmpty section then
                loadRootChildren dir

            else
                loadSectionChildren dir section
    in
    parentLoader
        |> BackendTask.andThen
            (\pages ->
                pages
                    |> List.map
                        (\page ->
                            loadSectionChildren dir page.slug
                                |> BackendTask.map
                                    (\children ->
                                        { slug = page.slug
                                        , frontmatter = page.frontmatter
                                        , sectionChildren = children
                                        }
                                    )
                        )
                    |> BackendTask.combine
            )


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


pageDirFromPath : String -> String -> String
pageDirFromPath contentRoot filePath =
    let
        prefix =
            contentRoot ++ "/"

        relative =
            if String.startsWith prefix filePath then
                String.dropLeft (String.length prefix) filePath

            else
                filePath
    in
    case List.reverse (String.split "/" relative) of
        _ :: dirs ->
            case List.reverse dirs of
                [] ->
                    ""

                segments ->
                    String.join "/" segments ++ "/"

        [] ->
            ""


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
