module LlmAgent.RequireModuleDoc exposing (rule)

{-| Requires every module to have a module-level documentation comment.

    -- not ok  (no {-| ... -} above the module declaration)
    module Component.Button exposing (..)

    -- ok
    module Component.Button exposing (..)
    {-| A button component with multiple visual variants and sizes.
    -}

Module documentation is the first thing an LLM coding agent reads when it
opens a file. A short description of purpose and usage dramatically reduces
the time needed to understand the module in context.

-}

import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Rule as Rule exposing (Rule)


type alias Context =
    { moduleDefinitionRange : Range
    }


{-| Reports modules that lack a `{-| ... -}` module documentation comment.
-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "LlmAgent.RequireModuleDoc"
        { moduleDefinitionRange = { start = { row = 1, column = 1 }, end = { row = 1, column = 1 } }
        }
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withModuleDocumentationVisitor moduleDocumentationVisitor
        |> Rule.fromModuleRuleSchema


moduleDefinitionVisitor : Node Module -> Context -> ( List (Rule.Error {}), Context )
moduleDefinitionVisitor node context =
    ( [], { context | moduleDefinitionRange = Node.range node } )


moduleDocumentationVisitor : Maybe (Node String) -> Context -> ( List (Rule.Error {}), Context )
moduleDocumentationVisitor maybeDoc context =
    case maybeDoc of
        Just _ ->
            ( [], context )

        Nothing ->
            ( [ Rule.error
                    { message = "Module is missing a documentation comment"
                    , details =
                        [ "Every module should begin with a {-| ... -} comment that describes its purpose, main exports, and any usage notes."
                        , "LLM coding agents rely on module documentation to quickly understand the role of a file without reading all of its source."
                        , "Add a comment directly below the module declaration, e.g.:\n\n    {-| A button component with Primary, Secondary, Ghost and Danger variants.\n    -}"
                        ]
                    }
                    context.moduleDefinitionRange
              ]
            , context
            )
