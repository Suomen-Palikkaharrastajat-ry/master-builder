module DesignTokens.Components exposing
    ( buttonTokenDeps
    , cardTokenDeps
    , alertTokenDeps
    , badgeTokenDeps
    , accordionTokenDeps
    , breadcrumbTokenDeps
    , buttonGroupTokenDeps
    , closeButtonTokenDeps
    , collapseTokenDeps
    , colorSwatchTokenDeps
    , dialogTokenDeps
    , dropdownTokenDeps
    , listGroupTokenDeps
    , navbarTokenDeps
    , paginationTokenDeps
    , placeholderTokenDeps
    , progressTokenDeps
    , sectionHeaderTokenDeps
    , spinnerTokenDeps
    , statsTokenDeps
    , tabsTokenDeps
    , tagTokenDeps
    , timelineTokenDeps
    , toastTokenDeps
    , toggleTokenDeps
    , tooltipTokenDeps
    )


{-| Component token mappings.

Each value lists the design token paths that the component depends on.

-}


{-| Action button or link-button. Variants: Primary, Secondary, Ghost, Danger. -}
buttonTokenDeps : List String
buttonTokenDeps =
    [ "color.semantic.background-accent"
    , "color.semantic.text-primary"
    , "spacing.space-2"
    , "spacing.space-4"
    , "typography.Body"
    ]

{-| Content container with optional header, footer, image, shadow. -}
cardTokenDeps : List String
cardTokenDeps =
    [ "color.semantic.border-default"
    , "spacing.space-4"
    , "spacing.space-6"
    ]

{-| Contextual feedback message. Types: Info, Success, Warning, Error. -}
alertTokenDeps : List String
alertTokenDeps =
    [ "color.semantic.text-primary"
    , "color.semantic.background-subtle"
    , "spacing.space-4"
    ]

{-| Small inline label. Colors: Gray, Blue, Green, Yellow, Red, Purple, Indigo. -}
badgeTokenDeps : List String
badgeTokenDeps =
    [ "typography.Caption"
    , "spacing.space-1"
    , "spacing.space-2"
    ]

{-| Collapsible sections using native <details>. -}
accordionTokenDeps : List String
accordionTokenDeps =
    [ "color.semantic.border-default"
    , "spacing.space-4"
    ]

{-| Navigation breadcrumb trail. -}
breadcrumbTokenDeps : List String
breadcrumbTokenDeps =
    [ "color.semantic.text-muted"
    , "typography.BodySmall"
    ]

{-| Horizontally grouped buttons. -}
buttonGroupTokenDeps : List String
buttonGroupTokenDeps =
    [ "color.semantic.border-default" ]

{-| Accessible close / dismiss button. -}
closeButtonTokenDeps : List String
closeButtonTokenDeps =
    [ "color.semantic.text-muted" ]

{-| Single collapsible section using <details>. -}
collapseTokenDeps : List String
collapseTokenDeps =
    [ "color.semantic.border-default" ]

{-| Color token display with hex, name, description, usage tags. -}
colorSwatchTokenDeps : List String
colorSwatchTokenDeps =
    [ "color.semantic.text-primary" ]

{-| Modal dialog overlay. -}
dialogTokenDeps : List String
dialogTokenDeps =
    [ "color.semantic.background-page"
    , "color.semantic.border-default"
    , "spacing.space-6"
    ]

{-| Disclosure dropdown using <details>/<summary>. -}
dropdownTokenDeps : List String
dropdownTokenDeps =
    [ "color.semantic.border-default"
    , "color.semantic.background-page"
    ]

{-| Vertical list with optional active/disabled states. -}
listGroupTokenDeps : List String
listGroupTokenDeps =
    [ "color.semantic.border-default" ]

{-| Top navigation bar with logo and links. -}
navbarTokenDeps : List String
navbarTokenDeps =
    [ "color.brand.lego-black"
    , "color.brand.lego-white"
    , "spacing.space-4"
    ]

{-| Page navigation control. -}
paginationTokenDeps : List String
paginationTokenDeps =
    [ "color.semantic.text-muted"
    , "color.semantic.border-default"
    ]

{-| Animated loading skeleton. -}
placeholderTokenDeps : List String
placeholderTokenDeps =
    [ "color.semantic.background-subtle" ]

{-| Horizontal progress bar. -}
progressTokenDeps : List String
progressTokenDeps =
    [ "color.semantic.background-subtle"
    , "color.semantic.background-accent"
    ]

{-| Section heading with optional description. -}
sectionHeaderTokenDeps : List String
sectionHeaderTokenDeps =
    [ "typography.Heading2"
    , "color.semantic.text-primary"
    ]

{-| Loading spinner animation. -}
spinnerTokenDeps : List String
spinnerTokenDeps =
    [ "motion.duration.base" ]

{-| Metric display grid. -}
statsTokenDeps : List String
statsTokenDeps =
    [ "color.semantic.text-muted"
    , "typography.Heading3"
    ]

{-| Tab navigation strip (stateless — host provides active index). -}
tabsTokenDeps : List String
tabsTokenDeps =
    [ "color.semantic.border-brand"
    , "color.semantic.text-muted"
    ]

{-| Removable tag / chip label. -}
tagTokenDeps : List String
tagTokenDeps =
    [ "typography.Caption"
    , "spacing.space-1"
    ]

{-| Vertical timeline for changelogs. -}
timelineTokenDeps : List String
timelineTokenDeps =
    [ "color.semantic.border-default"
    , "spacing.space-4"
    ]

{-| Notification message bar. -}
toastTokenDeps : List String
toastTokenDeps =
    [ "color.semantic.text-primary"
    , "color.semantic.background-page"
    , "motion.duration.base"
    ]

{-| On/off toggle switch. -}
toggleTokenDeps : List String
toggleTokenDeps =
    [ "color.semantic.background-accent"
    , "color.brand.lego-white"
    ]

{-| Hover/focus tooltip. -}
tooltipTokenDeps : List String
tooltipTokenDeps =
    [ "color.semantic.background-dark"
    , "color.semantic.text-on-dark"
    , "typography.Caption"
    ]
