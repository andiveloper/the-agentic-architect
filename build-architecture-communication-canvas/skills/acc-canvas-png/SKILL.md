---
name: acc-canvas-png
description: Renders a self-contained HTML canvas (e.g. docs/architecture-communication-canvas.html) to a full-page PNG using headless Chrome, capturing the WHOLE page so nothing is cut off. Use at the end of /build-architecture-communication-canvas (after the HTML is written) to produce docs/architecture-communication-canvas.png, or whenever an HTML overview needs a PNG snapshot.
disable-model-invocation: true
---

# ACC canvas -> PNG

Turns an already-rendered HTML overview into a single full-page PNG image using Chrome/Chromium in headless mode. This is a mechanical render step, not an analyst: it adds no content, it only screenshots the HTML.

The hard part is **not cutting the page off**: `chrome --headless --screenshot` only captures the viewport, so tall canvases get clipped. The bundled script avoids this by driving Chrome over the DevTools protocol - it measures the full rendered page (`Page.getLayoutMetrics`) and captures it with `captureBeyondViewport`, after waiting for the Mermaid diagrams to finish rendering. The result always contains the entire canvas.

## Requirements
- `python3` (standard library only - no pip installs).
- Google Chrome or Chromium (also accepts Microsoft Edge). The script auto-detects common locations; override with the `CHROME` env var or `--chrome`.

## How to run
Run the bundled script [assets/html-to-png.py](assets/html-to-png.py):

```bash
python3 <skill-dir>/assets/html-to-png.py \
  --html docs/architecture-communication-canvas.html \
  --out  docs/architecture-communication-canvas.png
```

`<skill-dir>` is this skill's installed directory (the agent knows its absolute path). Options:
- `--width <px>` CSS layout width; default `1640` (matches the canvas `max-width` plus margin).
- `--scale <n>` device scale factor for crispness; default `2` (Retina). The output pixel size is `width*scale x height*scale`.
- `--chrome <path>` explicit Chrome/Chromium binary.
- `--timeout <s>` max seconds to wait for load + diagrams; default `20`.

On success it prints the measured page size and the output path. It serves the HTML's own folder over a temporary local `127.0.0.1` server (so the Mermaid module loads and any relative assets resolve), screenshots it, then cleans up the server and the temporary Chrome profile.

## Behaviour and failure handling
- **Full page, no cutoff:** the capture height equals the page's full content height, so the header, all nine sections, both Mermaid diagrams, and the footer are always included.
- **Chrome missing:** the script exits with code `2` and a message telling the user to install Chrome or set `CHROME`. The PNG is itself an optional, on-request output (the draw.io canvas is the default output); report that the PNG was skipped rather than failing the whole run.
- **Other failure:** exit code `1`. Report it, but do not block on it.

## Notes
- The script is self-contained and ecosystem-agnostic; it works for any self-contained HTML page, not just the ACC canvas.
- Do not embed credentials or fetch private URLs; it only renders the given local HTML file.
