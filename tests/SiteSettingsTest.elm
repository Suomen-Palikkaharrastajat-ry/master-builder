module SiteSettingsTest exposing (suite)

{-| The Elm decoder against the resolver's real output.

A failure here means `packages/site-config/site-config.mjs` and
`SiteSettings.decoder` disagree, which would break every site at build time or,
for the apps, at startup.

-}

import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Lang exposing (Lang(..))
import SiteSettings
import SiteSettingsFixture
import Test exposing (Test, describe, test)


decoded : Result Decode.Error SiteSettings.Localized
decoded =
    Decode.decodeString SiteSettings.localizedDecoder SiteSettingsFixture.json


inLang : Lang -> (SiteSettings.SiteSettings -> a) -> Maybe a
inLang lang get =
    decoded
        |> Result.toMaybe
        |> Maybe.andThen (SiteSettings.forLang lang)
        |> Maybe.map get


suite : Test
suite =
    describe "SiteSettings"
        [ test "decodes the resolver output" <|
            \_ ->
                decoded
                    |> Result.map (\localized -> ( localized.default, localized.languages ))
                    |> Expect.equal (Ok ( Fi, [ Fi, En ] ))
        , test "each language has its own text" <|
            \_ ->
                ( inLang Fi (.site >> .title), inLang En (.site >> .title) )
                    |> Expect.equal ( Just "Palikkakalenteri", Just "Brick Calendar" )
        , test "language-neutral values are shared" <|
            \_ ->
                ( inLang Fi (.site >> .url), inLang En (.site >> .url) )
                    |> Expect.equal
                        ( Just "https://kalenteri.palikkaharrastajat.fi"
                        , Just "https://kalenteri.palikkaharrastajat.fi"
                        )
        , test "family defaults arrive: footer links without the site itself" <|
            \_ ->
                inLang Fi (.footer >> .links >> List.map .label)
                    |> Expect.equal
                        (Just
                            [ "Palikkakartta"
                            , "Palikkalinkit"
                            , "Palikkaoppaat"
                            , "Kotisivut"
                            , "Jäsenfoorumi"
                            , "Jäsenkortti"
                            , "Jäsenmaksu"
                            , "Tietosuoja"
                            ]
                        )
        , test "the config knows its own language" <|
            \_ ->
                ( inLang Fi .lang, inLang En .lang )
                    |> Expect.equal ( Just Fi, Just En )
        , test "Lang.isSwitch is true only for a request for another language" <|
            \_ ->
                [ Just "lang=en", Just "a=1&lang=en", Just "lang=fi", Just "lang=sv", Just "language=en", Just "", Nothing ]
                    |> List.map (Lang.isSwitch Fi)
                    |> Expect.equal [ True, True, False, False, False, False, False ]
        , test "fromFlags gives language, default and settings, or says why not" <|
            \_ ->
                let
                    flag =
                        Decode.decodeString Decode.value SiteSettingsFixture.json
                            |> Result.withDefault (Encode.object [])

                    good =
                        SiteSettings.fromFlags (Just "en") flag

                    bad =
                        SiteSettings.fromFlags Nothing (Encode.object [])
                in
                ( ( good.lang, good.default, good.site.site.title )
                , good.error
                , ( bad.site.site.title, Maybe.map (String.startsWith "The site configuration could not be read") bad.error )
                )
                    |> Expect.equal ( ( En, Fi, "Brick Calendar" ), Nothing, ( "", Just True ) )
        , test "Lang.attributeFor marks content in another language only" <|
            \_ ->
                ( List.length (Lang.attributeFor { interface = En, content = Fi })
                , List.length (Lang.attributeFor { interface = Fi, content = Fi })
                )
                    |> Expect.equal ( 1, 0 )
        , test "an app decodes its own [app] settings" <|
            \_ ->
                Decode.decodeString
                    (SiteSettings.appDecoder En (Decode.field "pocketbase_url" Decode.string))
                    SiteSettingsFixture.json
                    |> Expect.equal (Ok "https://data.palikkaharrastajat.fi")
        , test "pickLang honours a declared language and ignores anything else" <|
            \_ ->
                decoded
                    |> Result.map
                        (\localized ->
                            [ SiteSettings.pickLang (Just "en") localized
                            , SiteSettings.pickLang (Just "en-GB") localized
                            , SiteSettings.pickLang (Just "sv") localized
                            , SiteSettings.pickLang Nothing localized
                            , SiteSettings.pickLang (Just "en") { localized | languages = [ Fi ] }
                            ]
                        )
                    |> Expect.equal (Ok [ En, En, Fi, Fi, Fi ])
        , test "an undeclared language falls back to the default" <|
            \_ ->
                Decode.decodeString SiteSettings.localizedDecoder SiteSettingsFixture.json
                    |> Result.map (\localized -> { localized | configs = List.filter (\( l, _ ) -> l == Fi) localized.configs })
                    |> Result.toMaybe
                    |> Maybe.andThen (SiteSettings.forLang En)
                    |> Maybe.map (.site >> .title)
                    |> Expect.equal (Just "Palikkakalenteri")
        ]
