port module Ports exposing (SearchResult, focusMobileNav, performSearch, searchResults)

{-| Focus the first nav item in the mobile menu.
-}


port focusMobileNav : () -> Cmd msg


{-| Send a search query to JavaScript (lunr index).
-}
port performSearch : String -> Cmd msg


{-| Search results returned from JavaScript in ranked order.
-}
port searchResults : (List SearchResult -> msg) -> Sub msg


{-| Search result record passed between JS and Elm through ports.
-}
type alias SearchResult =
    { path : String
    , title : String
    , description : String
    }
