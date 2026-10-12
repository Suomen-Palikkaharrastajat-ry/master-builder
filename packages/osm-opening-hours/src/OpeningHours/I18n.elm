module OpeningHours.I18n exposing (Translations, english, finnish, forCode)


type alias Translations =
    { editorLabel : String
    , editorPlaceholder : String
    , editorHelpText : String
    , alwaysOpen : String
    , everyDay : String
    , closed : String
    , publicHolidays : String
    , monday : String
    , tuesday : String
    , wednesday : String
    , thursday : String
    , friday : String
    , saturday : String
    , sunday : String
    , onwards : String
    , errMissingDash : String
    , errMissingColon : String
    , errMissingPlus : String
    , errExpectedKeyword : String
    , errExtraText : String
    , errEmptyDays : String
    , errEmptyTimes : String
    , errInvalidInt : String
    , errSyntax : String
    , errUnknown : String
    }


finnish : Translations
finnish =
    { editorLabel = "Aukioloajat"
    , editorPlaceholder = "esim. Mo-Fr 10:00-18:00; Sa 10:00-15:00"
    , editorHelpText = "Esimerkki: 'Mo-Fr 09:00-17:00; Sa 10:00-15:00'. Säännöt erotetaan puolipisteellä (;)."
    , alwaysOpen = "Aina auki"
    , everyDay = "Joka päivä"
    , closed = "Suljettu"
    , publicHolidays = "Pyhäpäivät"
    , monday = "maanantai"
    , tuesday = "tiistai"
    , wednesday = "keskiviikko"
    , thursday = "torstai"
    , friday = "perjantai"
    , saturday = "lauantai"
    , sunday = "sunnuntai"
    , onwards = " eteenpäin"
    , errMissingDash = "Aikaväli näyttää olevan kesken. Odotettiin viivaa '-' (esim. 'Mo-Fr' tai '10:00-18:00')."
    , errMissingColon = "Aika on väärässä muodossa. Odotettiin kaksoispistettä ':' (esim. '10:30')."
    , errMissingPlus = "Odotettiin plussaa '+' (esim. '10:00+')."
    , errExpectedKeyword = "Odotettiin avainsanaa (kuten 'Mo', 'Tu', 'Jan', 'off', jne.)."
    , errExtraText = "Ylimääräistä tekstiä, jota ei voitu ymmärtää. Varmista, että säännöt on erotettu puolipisteellä ';'."
    , errEmptyDays = "Odotettiin päivää (esim. 'Mo') tai listaa päivistä."
    , errEmptyTimes = "Odotettiin aikaa (esim. '10:00-18:00')."
    , errInvalidInt = "Odotettiin kelvollista numeroa ajalle."
    , errSyntax = "Syntaksivirhe. Tarkista muoto (esim. 'Mo-Fr 09:00-17:00')."
    , errUnknown = "Tuntematon virhe."
    }


english : Translations
english =
    { editorLabel = "Opening hours"
    , editorPlaceholder = "e.g. Mo-Fr 10:00-18:00; Sa 10:00-15:00"
    , editorHelpText = "Example: 'Mo-Fr 09:00-17:00; Sa 10:00-15:00'. Rules are separated with a semicolon (;)."
    , alwaysOpen = "Always open"
    , everyDay = "Every day"
    , closed = "Closed"
    , publicHolidays = "Public holidays"
    , monday = "Monday"
    , tuesday = "Tuesday"
    , wednesday = "Wednesday"
    , thursday = "Thursday"
    , friday = "Friday"
    , saturday = "Saturday"
    , sunday = "Sunday"
    , onwards = " onwards"
    , errMissingDash = "The range looks unfinished. Expected a dash '-' (e.g. 'Mo-Fr' or '10:00-18:00')."
    , errMissingColon = "The time is in the wrong format. Expected a colon ':' (e.g. '10:30')."
    , errMissingPlus = "Expected a plus '+' (e.g. '10:00+')."
    , errExpectedKeyword = "Expected a keyword (such as 'Mo', 'Tu', 'Jan', 'off')."
    , errExtraText = "Extra text that could not be understood. Make sure rules are separated with a semicolon ';'."
    , errEmptyDays = "Expected a day (e.g. 'Mo') or a list of days."
    , errEmptyTimes = "Expected a time (e.g. '10:00-18:00')."
    , errInvalidInt = "Expected a valid number for the time."
    , errSyntax = "Syntax error. Check the format (e.g. 'Mo-Fr 09:00-17:00')."
    , errUnknown = "Unknown error."
    }


{-| The translations for a two-letter language code; Finnish for an unknown one.
-}
forCode : String -> Translations
forCode code =
    case code of
        "en" ->
            english

        _ ->
            finnish
