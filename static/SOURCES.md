# Self-hosted static files

Served by Crow at `/static/<path>` from `./static/` (the explorer's
working directory). Nothing on the explorer's pages is loaded from
another site.

| Path | Source | License |
|---|---|---|
| `img/logo.png`, `img/icon.ico` | https://bitlitas.lt/img/logo.png, https://bitlitas.lt/img/favicon/icon.ico | Bitlitas |
| `img/fbshare_explorer.png` | https://bitlitas.lt/img/fbshare_explorer.png | Bitlitas |
| `jquery-2.1.1/` | https://code.jquery.com/jquery-2.1.1.min.js | MIT |
| `bootstrap-3.1.1/` | npm `bootstrap@3.1.1` `dist/` (css, js, fonts) | MIT |
| `font-awesome-4.7.0/` | npm `font-awesome@4.7.0` (css, fonts) | CSS: MIT, fonts: SIL OFL 1.1 |
| `fonts/` | Google Fonts, Montserrat and Roboto Condensed, latin + latin-ext subsets only | SIL OFL 1.1 / Apache 2.0 |

The library files are byte-identical to the copies on a second CDN
(cdnjs / netdna.bootstrapcdn.com). The only exception is jQuery,
where the cdnjs copy adds a trailing `sourceMappingURL` comment.
