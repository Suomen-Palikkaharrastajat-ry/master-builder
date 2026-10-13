port module Ports exposing (SearchResult, onScroll, performSearch, scrollToTop, searchResults)

{-| Send a search query to JavaScript (lunr index).
-}


port performSearch : String -> Cmd msg


{-| Search results returned from JavaScript in ranked order.
-}
port searchResults : (List SearchResult -> msg) -> Sub msg


{-| Smooth-scroll the page to the top.
-}
port scrollToTop : () -> Cmd msg


{-| Receive the current vertical scroll position from JavaScript.
-}
port onScroll : (Float -> msg) -> Sub msg


{-| Search result record passed between JS and Elm through ports.
-}
type alias SearchResult =
    { path : String
    , title : String
    , description : String
    }
