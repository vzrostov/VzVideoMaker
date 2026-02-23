# VzVideoMaker

A small Windows PowerShell + FFmpeg template to cut a fragment from a long video and generate a vertical 9:16 clip (TikTok / Shorts / Reels) with:

- optional top title bar + centered title text
- optional subtitles overlay (.ass preferred, .srt supported)
- optional GIF icon overlay at the end of the clip

Use **JSON presets** to run the script.

## Requirements

- Windows PowerShell 5.1
- FFmpeg available in `PATH` (or update `$FFMPEG` in `make-video.ps1`)

## Quick start

1. Put your input files into:
   - `Data/In` (input video, subtitles, icon)
   - `Data/Out` (output will be created here)
2. Create/edit a preset JSON file (see `presetsTest/` examples).
3. Run:

```powershell
powershell.exe -NoProfile -File .\run-preset.ps1 -Preset .\presetsTest\example-no-subs.json
```

If you want the console window to stay open (e.g. when starting by double-click), use:

```powershell
powershell.exe -NoProfile -File .\run-preset-pause.ps1 -Preset .\presetsTest\example-no-subs.json
```

## Preset format (JSON)

A preset is a JSON object with keys matching `make-video.ps1` parameters.

### Main keys

- `InFile` (string) — input video file path
- `OutFile` (string) — output video file path
- `T1` (string) — start time (ffmpeg format, e.g. `00:12:34.500`)
- `T2` (string) — end time (ffmpeg format)
- `Title` (string) — title text
- `Subs` (string) — path to `.ass`/`.srt` subtitles file; use `""` to skip subtitles

### Advanced keys

- `LayoutMode` ("FIT" | "CROP")
- `SrcCropL` (int)
- `SrcCropR` (int)
- `TopBarH` (int)
- `FontFile` (string)
- `TitleSize` (int)
- `SubForceStyle` (string)
- `IconFile` (string)

Notes:
- If a preset contains **relative paths**, they are resolved under:
  - `Data/In` for `InFile`, `Subs`, `FontFile`, `IconFile`
  - `Data/Out` for `OutFile`
- In JSON on Windows, prefer using forward slashes in paths (e.g. `C:/Windows/Fonts/arialbd.ttf`) to avoid escaping backslashes.

## Project files

- `make-video.ps1` — main FFmpeg pipeline script
- `run-preset.ps1` — reads a JSON preset and runs `make-video.ps1` with those parameters
- `run-preset-pause.ps1` — same as `run-preset.ps1`, but waits for a key press at the end
- `presetsTest/` — example presets

## License

MIT. See [LICENSE](LICENSE).

