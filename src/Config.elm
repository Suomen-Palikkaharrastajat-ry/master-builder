module Config exposing (Config, languageTag, task)

{-| Site-wide configuration loaded from content/config.toml at build time.

The file is layered on the family defaults and resolved per language by
`packages/site-config`; the site is built in its default language.

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import ContentDir
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode as Encode
import Lang exposing (Lang(..))
import LanguageTag exposing (LanguageTag)
import LanguageTag.Language
import LanguageTag.Region
import SiteSettings exposing (SiteSettings)


type alias Config =
    SiteSettings


task : BackendTask FatalError Config
task =
    ContentDir.backendTask
        |> BackendTask.andThen
            (\dir ->
                BackendTask.Custom.run "readSiteConfig"
                    (Encode.string (dir ++ "/config.toml"))
                    (SiteSettings.localizedDecoder
                        |> Decode.andThen
                            (\localized ->
                                case SiteSettings.forLang localized.default localized of
                                    Just config ->
                                        Decode.succeed config

                                    Nothing ->
                                        Decode.fail "config.toml has no configuration for its default language"
                            )
                    )
            )
        |> BackendTask.allowFatal


{-| The BCP 47 tag of the language the site is built in.
-}
languageTag : Config -> LanguageTag
languageTag config =
    let
        subtags =
            LanguageTag.emptySubtags
    in
    case config.lang of
        Fi ->
            LanguageTag.Language.fi
                |> LanguageTag.build { subtags | region = Just LanguageTag.Region.fi }

        En ->
            LanguageTag.Language.en
                |> LanguageTag.build { subtags | region = Just LanguageTag.Region.gb }
