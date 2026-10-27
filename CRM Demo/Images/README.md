# The dashboard icons

One icon per tile of the Dashboard page, in both demos. The file is named after
the tile, so there is nothing to look up: `New.svg` is the icon of the **New**
tile, `ProposalSent.svg` of **Proposal Sent**, and so on.

| File | Tile | Taken from | Why that one |
|---|---|---|---|
| `New.svg` | New | `idea.svg` | A lead that just arrived and nobody has called yet |
| `Active.svg` | Active | `synchronize.svg` | Somebody is working on it |
| `ProposalSent.svg` | Proposal Sent | `document.svg` | The proposal is a document, and it is out |
| `Closed.svg` | Closed | `ok.svg` | Ended - won **or** lost, so a neutral tick and not a trophy |
| `Inactive.svg` | Inactive | `expired.svg` | Parked |
| `Total.svg` | Total | `bar_chart.svg` | Everything you have, whatever its status |

Six different hues on purpose: on a dashboard the colour is read before the
label. Three of the first choices were thrown away because they did not survive
24 pixels on a dark background - `signature.svg` is a thin blue squiggle,
`statistics.svg` has a dark grey tripod, `process.svg` is thin and magenta.

## Where they come from

The **Flat Color Icons** of Icons8, as the demo of
[SvgIconImageList](https://github.com/EtheaDev/SVGIconImageList) ships them:
`Demo\svg_examples\flat-color-icons\svg`. Released under **MIT or the Good Boy
License**, "free icons for personal and commercial use, no credits required" -
so this page is courtesy, not a legal notice.

## png\

What the two demos actually load: the same icons rasterised at 32, 48, 64, 96
and 128 pixels, which is what an image list wants in order to follow the DPI of
the monitor. They are embedded in the two forms (a `TImageCollection` read by
`TVirtualImage` in the VCL demo, a multi-resolution `TImageList` read by
`TGlyph` in the FMX one), so the applications do not read this folder at
runtime: it is the source the forms were filled from.

Change an SVG, and regenerate them with the tool of
[SVGShellExtensions](https://github.com/EtheaDev/SVGShellExtensions):

```
SVGToPNG.exe convert -in:"CRM Demo\Images\*.svg" -size:32,48,64,96,128 -out:"CRM Demo\Images\png"
```

Then put them back into the two forms - in the VCL demo as `Image.Data` blobs of
`ImageCollection1`, in the FMX one as the `PNG` items of the `MultiResBitmap`
of `TileImages`.
