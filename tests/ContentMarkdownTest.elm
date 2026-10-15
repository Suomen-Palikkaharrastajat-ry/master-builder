module ContentMarkdownTest exposing (suite)

{-| Tests for root slug exclusion and markdown image path normalization.
-}

import ContentMarkdown
import Expect
import MarkdownRenderer.Helpers as Helpers
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "ContentMarkdown and Helpers"
        [ describe "ContentMarkdown.isExcludedRootSlug"
            [ test "excludes README (uppercase and lowercase)" <|
                \_ ->
                    Expect.all
                        [ \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "README")
                        , \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "readme")
                        , \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "Readme")
                        ]
                        ()
            , test "excludes AGENTS (uppercase and lowercase)" <|
                \_ ->
                    Expect.all
                        [ \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "AGENTS")
                        , \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "agents")
                        ]
                        ()
            , test "excludes common repository meta docs like LICENSE and CONTRIBUTING" <|
                \_ ->
                    Expect.all
                        [ \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "LICENSE")
                        , \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "contributing")
                        , \() -> Expect.equal True (ContentMarkdown.isExcludedRootSlug "claude")
                        ]
                        ()
            , test "does not exclude legitimate content page slugs" <|
                \_ ->
                    Expect.all
                        [ \() -> Expect.equal False (ContentMarkdown.isExcludedRootSlug "about")
                        , \() -> Expect.equal False (ContentMarkdown.isExcludedRootSlug "components")
                        , \() -> Expect.equal False (ContentMarkdown.isExcludedRootSlug "index")
                        , \() -> Expect.equal False (ContentMarkdown.isExcludedRootSlug "blog")
                        ]
                        ()
            ]
        , describe "Helpers.normalizeSrc"
            [ test "normalizes images/ at content root to /images/" <|
                \_ ->
                    Expect.equal "/images/photo.png" (Helpers.normalizeSrc "" "images/photo.png")
            , test "normalizes images/ inside a section to root /images/" <|
                \_ ->
                    Expect.equal "/images/photo.png" (Helpers.normalizeSrc "blog/" "images/photo.png")
            , test "normalizes ./images/ inside a section to root /images/" <|
                \_ ->
                    Expect.equal "/images/photo.png" (Helpers.normalizeSrc "blog/" "./images/photo.png")
            , test "normalizes ../images/ inside a section to root /images/" <|
                \_ ->
                    Expect.equal "/images/photo.png" (Helpers.normalizeSrc "blog/" "../images/photo.png")
            , test "preserves absolute /images/ path" <|
                \_ ->
                    Expect.equal "/images/photo.png" (Helpers.normalizeSrc "blog/" "/images/photo.png")
            , test "resolves section-relative non-images paths using pageDir" <|
                \_ ->
                    Expect.equal "/blog/diagram.svg" (Helpers.normalizeSrc "blog/" "./diagram.svg")
            , test "preserves external URLs" <|
                \_ ->
                    Expect.equal "https://example.com/logo.png" (Helpers.normalizeSrc "blog/" "https://example.com/logo.png")
            ]
        ]
