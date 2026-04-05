module Component.Gallery exposing (Columns(..), view)

{-| Generic section shell: sub-section heading with a responsive grid of arbitrary HTML items.
-}

import Component.SectionHeader as SectionHeader
import Html exposing (Html)
import Tailwind as Tw exposing (classes)
import Tailwind.Breakpoints as Bp
import Tailwind.Theme as Th
import TailwindExtra as TwEx


{-| Responsive column layout options.

  - `Two` — always 2 columns (suitable for small items)
  - `Three` — 2 cols on mobile, 3 on md+
  - `Four` — 2 cols on mobile, 3 on md, 4 on lg
  - `TwoWide` — 1 col on mobile, 2 on sm+ (for wider items)

-}
type Columns
    = Two
    | Three
    | Four
    | TwoWide


{-| Render a sub-section heading followed by a responsive grid of items.
-}
view : { title : String, description : Maybe String, columns : Columns, items : List (Html msg) } -> Html msg
view config =
    Html.div [ classes [ TwEx.space_y Th.s4 ] ]
        [ SectionHeader.viewSub { title = config.title, description = config.description }
        , Html.div
            [ classes ([ TwEx.not_prose, Tw.grid, Tw.gap Th.s4 ] ++ columnClasses config.columns) ]
            config.items
        ]


columnClasses : Columns -> List Tw.Tailwind
columnClasses cols =
    case cols of
        Two ->
            [ Tw.grid_cols_2 ]

        Three ->
            [ Tw.grid_cols_2, Bp.md [ Tw.grid_cols_3 ] ]

        Four ->
            [ Tw.grid_cols_2, Bp.md [ Tw.grid_cols_3 ], Bp.lg [ Tw.grid_cols_4 ] ]

        TwoWide ->
            [ Tw.grid_cols_1, Bp.sm [ Tw.grid_cols_2 ] ]
