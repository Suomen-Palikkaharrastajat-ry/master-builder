module OpeningHours exposing (..)

type Day
    = Mo | Tu | We | Th | Fr | Sa | Su

type Month
    = Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec

type DaySelector
    = SingleDay Day
    | DayRange Day Day
    | PublicHoliday

type MonthSelector
    = SingleMonth Month
    | MonthRange Month Month

type alias Time =
    { hour : Int, minute : Int }

type TimeSpan
    = TimeRange Time Time
    | OpenEnded Time

type RuleStatus
    = Open (List TimeSpan)
    | Off

type alias Rule =
    { months : Maybe (List MonthSelector)
    , days : Maybe (List DaySelector)
    , status : RuleStatus
    }

type OpeningHours
    = Open247
    | Rules (List Rule)
