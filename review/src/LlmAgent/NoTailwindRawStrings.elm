module LlmAgent.NoTailwindRawStrings exposing (rule)

{-| Forbids the use of `Tw.raw` (or `Tailwind.raw`) for Tailwind class strings.

    -- not ok
    Tw.raw "bg-white"
    Tw.raw "group"

    -- ok
    Tw.bg_white
    Tw.group

Using typed Tailwind tokens instead of raw strings makes the codebase
consistent and self-documenting. LLM coding agents can discover, refactor,
and verify typed tokens; opaque strings cannot be statically analysed.

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Rule)


{-| Reports uses of `Tw.raw` or `Tailwind.raw`.
-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "LlmAgent.NoTailwindRawStrings" ()
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> () -> ( List (Rule.Error {}), () )
expressionVisitor node () =
    case Node.value node of
        Expression.Application (functionNode :: _) ->
            case Node.value functionNode of
                Expression.FunctionOrValue qualifier "raw" ->
                    if List.member qualifier [ [ "Tw" ], [ "Tailwind" ] ] then
                        ( [ Rule.error
                                { message = "Avoid Tw.raw — use a typed Tailwind token instead"
                                , details =
                                    [ "Tw.raw \"some-class\" is an opaque string. LLM coding agents cannot refactor, verify, or autocomplete raw strings the way they can typed tokens."
                                    , "Replace it with the equivalent typed token, e.g. Tw.bg_white, Tw.divide_gray_200, Tw.group."
                                    , "If no typed token exists for the class you need, add it to the Tailwind configuration so a token is generated."
                                    ]
                                }
                                (Node.range node)
                          ]
                        , ()
                        )

                    else
                        ( [], () )

                _ ->
                    ( [], () )

        _ ->
            ( [], () )
