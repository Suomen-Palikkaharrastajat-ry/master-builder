module ContentDir exposing (backendTask)

{-| Reads the CONTENT\_DIR environment variable to determine where Markdown
content files are located. Defaults to "template" so the bundled example
content works without any configuration.

Set CONTENT\_DIR=content (or any path) to point at a different directory.

-}

import BackendTask exposing (BackendTask)
import BackendTask.Env as Env


backendTask : BackendTask error String
backendTask =
    Env.get "CONTENT_DIR"
        |> BackendTask.map (Maybe.withDefault "template")
