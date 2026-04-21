# Recording guide (OBS)

Starter OBS scene collection for recording the demo browser with a zoom scene: `browser-zoom-scene-collection.json`. Two scenes (`Normal`, `Zoom`), one `Browser Window` source.

## Import

1. OBS → Scene Collection → Import
2. Pick `recording/browser-zoom-scene-collection.json`
3. Switch to the imported collection

## Fix the source

Window IDs differ per machine/session, so after import:

1. In each scene click `Browser Window`
2. Properties → pick your actual browser window
3. In `Normal`: Transform → Fit to screen (if needed)

## Hotkeys

Set these manually in OBS (File → Settings → Hotkeys):

- `F1` → Switch to scene `Normal`
- `F2` → Switch to scene `Zoom`

## Tuning the zoom

In the `Zoom` scene, edit Transform on the source:

- `Scale`: bigger = more zoom
- `Position X/Y`: move the zoom target
- `Crop top/left/right/bottom`: isolate an area

Sensible starting values:

- scale: 1.5 to 2.2
- fade: 200 to 300 ms

## Recommended: multiple zoom scenes

Instead of re-editing one zoom scene, duplicate it after import:

- `Zoom Left`
- `Zoom Center`
- `Zoom Right`

Then bind:

- `F2` → Zoom Left
- `F3` → Zoom Center
- `F4` → Zoom Right

This is much more usable during live demos than tweaking a single zoom scene.
