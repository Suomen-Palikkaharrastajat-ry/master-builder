module SearchIndex exposing (SearchDocument, documentsTask, encodeDocument)

{-| Search index document generation for client-side site search.
-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import ContentDir
import ContentMarkdown
import FatalError exposing (FatalError)
import Frontmatter exposing (Frontmatter)
import Json.Encode as Encode
import MarkdownRenderer.Helpers as Helpers
import Regex


{-| Serializable search document used by `search-index.json`.
-}
type alias SearchDocument =
    { id : String
    , path : String
    , title : String
    , description : String
    , body : String
    }


{-| Build all searchable documents from the current content directory.
-}
documentsTask : BackendTask FatalError (List SearchDocument)
documentsTask =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\contentRoot ->
                BackendTask.map4 combineDocumentLists
                    (rootDocumentTask contentRoot)
                    (flatDocumentTask contentRoot)
                    (sectionIndexDocumentTask contentRoot)
                    (sectionPageDocumentTask contentRoot)
            )
        |> BackendTask.map (List.sortBy .path)


{-| Encode a search document to JSON.
-}
encodeDocument : SearchDocument -> Encode.Value
encodeDocument document =
    Encode.object
        [ ( "id", Encode.string document.id )
        , ( "path", Encode.string document.path )
        , ( "title", Encode.string document.title )
        , ( "description", Encode.string document.description )
        , ( "body", Encode.string document.body )
        ]


rootDocumentTask : String -> BackendTask FatalError (List SearchDocument)
rootDocumentTask contentRoot =
    documentTask contentRoot "/" (contentRoot ++ "/index.md")
        |> BackendTask.map maybeToList


flatDocumentTask : String -> BackendTask FatalError (List SearchDocument)
flatDocumentTask contentRoot =
    Glob.succeed identity
        |> Glob.match (Glob.literal (contentRoot ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (\slugs ->
                slugs
                    |> List.filter (\slug -> slug /= "index" && not (ContentMarkdown.isPartialSlug slug))
                    |> List.map
                        (\slug ->
                            documentTask
                                contentRoot
                                ("/" ++ slug)
                                (contentRoot ++ "/" ++ slug ++ ".md")
                        )
                    |> BackendTask.combine
            )
        |> BackendTask.map (List.filterMap identity)


sectionIndexDocumentTask : String -> BackendTask FatalError (List SearchDocument)
sectionIndexDocumentTask contentRoot =
    Glob.succeed identity
        |> Glob.match (Glob.literal (contentRoot ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/index.md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (\sections ->
                sections
                    |> List.filter (not << ContentMarkdown.isPartialSlug)
                    |> List.map
                        (\section ->
                            documentTask
                                contentRoot
                                ("/" ++ section)
                                (contentRoot ++ "/" ++ section ++ "/index.md")
                        )
                    |> BackendTask.combine
            )
        |> BackendTask.map (List.filterMap identity)


sectionPageDocumentTask : String -> BackendTask FatalError (List SearchDocument)
sectionPageDocumentTask contentRoot =
    Glob.succeed Tuple.pair
        |> Glob.match (Glob.literal (contentRoot ++ "/"))
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (\pairs ->
                pairs
                    |> List.filter
                        (\( section, slug ) ->
                            slug
                                /= "index"
                                && not (ContentMarkdown.isPartialSlug section)
                                && not (ContentMarkdown.isPartialSlug slug)
                        )
                    |> List.map
                        (\( section, slug ) ->
                            documentTask
                                contentRoot
                                ("/" ++ section ++ "/" ++ slug)
                                (contentRoot ++ "/" ++ section ++ "/" ++ slug ++ ".md")
                        )
                    |> BackendTask.combine
            )
        |> BackendTask.map (List.filterMap identity)


documentTask : String -> String -> String -> BackendTask FatalError (Maybe SearchDocument)
documentTask contentRoot path filePath =
    ContentMarkdown.loadPage contentRoot filePath
        |> BackendTask.map
            (\pageData ->
                if shouldIncludeInIndex pageData.frontmatter then
                    Just
                        { id = path
                        , path = path
                        , title = pageData.frontmatter.title
                        , description = pageData.frontmatter.description
                        , body = searchableBody pageData.body
                        }

                else
                    Nothing
            )


shouldIncludeInIndex : Frontmatter -> Bool
shouldIncludeInIndex frontmatter =
    frontmatter.published && not (robotsContainsNoindex frontmatter.robots)


robotsContainsNoindex : Maybe String -> Bool
robotsContainsNoindex maybeRobots =
    maybeRobots
        |> Maybe.map String.toLower
        |> Maybe.map (String.contains "noindex")
        |> Maybe.withDefault False


searchableBody : String -> String
searchableBody rawBody =
    String.join " " [ extractAttributeValues rawBody, rawBody ]
        |> Helpers.decodeHtmlEntities
        |> stripCodeBlocks
        |> stripHtmlTags
        |> stripMarkdownLinks
        |> stripMarkdownPunctuation
        |> collapseWhitespace
        |> String.trim


extractAttributeValues : String -> String
extractAttributeValues rawBody =
    case Regex.fromString "(title|summary|name|subtitle)=\"([^\"]+)\"" of
        Nothing ->
            ""

        Just regex ->
            rawBody
                |> Regex.find regex
                |> List.filterMap
                    (\match ->
                        case match.submatches of
                            _ :: maybeValue :: _ ->
                                maybeValue

                            _ ->
                                Nothing
                    )
                |> String.join " "


stripCodeBlocks : String -> String
stripCodeBlocks =
    replaceRegex "```[\\s\\S]*?```" " "


stripHtmlTags : String -> String
stripHtmlTags =
    replaceRegex "<[^>]+>" " "


stripMarkdownLinks : String -> String
stripMarkdownLinks rawBody =
    case Regex.fromString "\\[([^\\]]+)\\]\\([^\\)]+\\)" of
        Nothing ->
            rawBody

        Just regex ->
            Regex.replace regex
                (\match ->
                    case match.submatches of
                        maybeLabel :: _ ->
                            Maybe.withDefault "" maybeLabel

                        _ ->
                            ""
                )
                rawBody


stripMarkdownPunctuation : String -> String
stripMarkdownPunctuation =
    replaceRegex "[\\[\\]\\(\\)!`*_>#~|]+" " "


collapseWhitespace : String -> String
collapseWhitespace =
    replaceRegex "\\s+" " "


replaceRegex : String -> String -> String -> String
replaceRegex pattern replacement input =
    case Regex.fromString pattern of
        Nothing ->
            input

        Just regex ->
            Regex.replace regex (\_ -> replacement) input


combineDocumentLists :
    List SearchDocument
    -> List SearchDocument
    -> List SearchDocument
    -> List SearchDocument
    -> List SearchDocument
combineDocumentLists root flat sectionIndexes sectionPages =
    root ++ flat ++ sectionIndexes ++ sectionPages


maybeToList : Maybe a -> List a
maybeToList maybeItem =
    case maybeItem of
        Just item ->
            [ item ]

        Nothing ->
            []
