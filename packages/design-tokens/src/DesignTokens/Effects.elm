module DesignTokens.Effects exposing
    ( shadowSm
    , shadowMd
    , shadowLg
    , shadowXl
    , shadow2xl
    , shadowNone
    , zDropdown
    , zSticky
    , zFixed
    , zModal
    , zPopover
    , zTooltip
    )


{-| Shadow and z-index tokens. -}


{-| Subtle: inputs, small cards. -}
shadowSm : String
shadowSm =
    "0 1px 2px 0 rgb(0 0 0 / 0.05)"

{-| Default: cards, dropdowns. -}
shadowMd : String
shadowMd =
    "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)"

{-| Elevated: popovers, floating panels. -}
shadowLg : String
shadowLg =
    "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)"

{-| High: modals, dialogs. -}
shadowXl : String
shadowXl =
    "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)"

{-| Highest: full-screen overlays. -}
shadow2xl : String
shadow2xl =
    "0 25px 50px -12px rgb(0 0 0 / 0.25)"

{-| No shadow — reset or disabled state. -}
shadowNone : String
shadowNone =
    "0 0 #0000"



{-| Dropdown menus, select popups. -}
zDropdown : Int
zDropdown =
    10

{-| Sticky headers, floating action buttons. -}
zSticky : Int
zSticky =
    20

{-| Fixed navbars, tab bars. -}
zFixed : Int
zFixed =
    30

{-| Modal dialogs and drawer overlays. -}
zModal : Int
zModal =
    40

{-| Popovers, tooltips above modals. -}
zPopover : Int
zPopover =
    50

{-| Highest interactive layer — tooltips. -}
zTooltip : Int
zTooltip =
    60
