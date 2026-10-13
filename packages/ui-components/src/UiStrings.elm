module UiStrings exposing (UiStrings, forLang)

{-| Text of the shared layout and components, one record per language.

These labels are the same on every site, so they ship with the components
instead of being repeated in each site's configuration or translations.

@docs UiStrings, forLang

-}

import Lang exposing (Lang(..))


{-| Every label the shared layout and components render themselves.

`thisLanguage` is the text of a link that switches to this language, written
in the language itself ("Suomeksi", "In English").

-}
type alias UiStrings =
    { thisLanguage : String
    , skipToContent : String
    , mainNav : String
    , mobileMenu : String
    , openMenu : String
    , closeMenu : String
    , backToTop : String
    , close : String
    , notifications : String
    , newTabHint : String
    , breadcrumb : String
    , pagination : String
    , previous : String
    , next : String
    , home : String
    , search : String
    , searchDescription : String
    , searching : String -> String
    , noResults : String -> String
    , resultCount : Int -> String
    , searchPage : String
    , searchIntro : String
    , searchHint : String
    , searchEmptyQuery : String
    , tableOfContents : String
    , preview : String
    , example : String
    , recommended : String
    , pageNotFoundTitle : String
    , pageNotFound : String
    , unexpectedErrorTitle : String
    , unexpectedError : String
    }


{-| The labels for a language.
-}
forLang : Lang -> UiStrings
forLang lang =
    case lang of
        Fi ->
            { thisLanguage = "Suomeksi"
            , skipToContent = "Siirry pääsisältöön"
            , mainNav = "Päävalikko"
            , mobileMenu = "Mobiilivalikko"
            , openMenu = "Avaa valikko"
            , closeMenu = "Sulje valikko"
            , backToTop = "Takaisin ylös"
            , close = "Sulje"
            , notifications = "Ilmoitukset"
            , newTabHint = "(avautuu uuteen välilehteen)"
            , breadcrumb = "Murupolku"
            , pagination = "Sivutus"
            , previous = "Edellinen"
            , next = "Seuraava"
            , home = "Etusivu"
            , search = "Hae sivustolta"
            , searchDescription = "Hae sivuston sisällöistä."
            , searching = \query -> "Haetaan tuloksia hakusanalle \"" ++ query ++ "\"..."
            , noResults = \query -> "Ei hakutuloksia hakusanalle \"" ++ query ++ "\"."
            , resultCount =
                \count ->
                    if count == 1 then
                        "1 hakutulos"

                    else
                        String.fromInt count ++ " hakutulosta"
            , searchPage = "Haku"
            , searchIntro = "Hae sivuston sivuja otsikon, kuvauksen ja sisällön perusteella."
            , searchHint = "Kirjoita hakusana ja tulokset päivittyvät automaattisesti."
            , searchEmptyQuery = "Anna hakusana, niin näytämme siihen sopivat sivut."
            , tableOfContents = "Sisällys"
            , preview = "Esikatselu"
            , example = "Esimerkki"
            , recommended = "Suositeltu"
            , pageNotFoundTitle = "Sivua ei löytynyt"
            , pageNotFound = "Sivua ei löytynyt. Tarkista osoite."
            , unexpectedErrorTitle = "Odottamaton virhe"
            , unexpectedError = "Jokin meni vikaan."
            }

        En ->
            { thisLanguage = "In English"
            , skipToContent = "Skip to main content"
            , mainNav = "Main menu"
            , mobileMenu = "Mobile menu"
            , openMenu = "Open menu"
            , closeMenu = "Close menu"
            , backToTop = "Back to top"
            , close = "Close"
            , notifications = "Notifications"
            , newTabHint = "(opens in a new tab)"
            , breadcrumb = "Breadcrumb"
            , pagination = "Pagination"
            , previous = "Previous"
            , next = "Next"
            , home = "Home"
            , search = "Search the site"
            , searchDescription = "Search the site's content."
            , searching = \query -> "Searching for \"" ++ query ++ "\"..."
            , noResults = \query -> "No results for \"" ++ query ++ "\"."
            , resultCount =
                \count ->
                    if count == 1 then
                        "1 result"

                    else
                        String.fromInt count ++ " results"
            , searchPage = "Search"
            , searchIntro = "Search the site's pages by title, description and content."
            , searchHint = "Type a search term; results update automatically."
            , searchEmptyQuery = "Enter a search term to see matching pages."
            , tableOfContents = "Contents"
            , preview = "Preview"
            , example = "Example"
            , recommended = "Recommended"
            , pageNotFoundTitle = "Page not found"
            , pageNotFound = "Page not found. Check the address."
            , unexpectedErrorTitle = "Unexpected error"
            , unexpectedError = "Something went wrong."
            }
