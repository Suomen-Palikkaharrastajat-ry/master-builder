module OpeningHours.I18n exposing (Translations, finnish)

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
    , monday = "Maanantai"
    , tuesday = "Tiistai"
    , wednesday = "Keskiviikko"
    , thursday = "Torstai"
    , friday = "Perjantai"
    , saturday = "Lauantai"
    , sunday = "Sunnuntai"
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
