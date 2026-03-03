# VzVideoMaker

A small Windows PowerShell + FFmpeg template to cut a fragment from a long video and generate a vertical 9:16 clip (TikTok / Shorts / Reels) with:

- optional top title bar + centered title text
- optional subtitles overlay (.ass preferred, .srt supported)
- optional GIF icon overlay at the end of the clip (can be disabled)

## Features

- **Customizable Title Bar**: Add a customizable title bar to your video with background color, alpha transparency, and font settings.
- **Subtitles**: Support for subtitles (.ass and .srt), with customizable background color and transparency.
- **Two Layout Modes**: Choose between CROP and FIT layout modes for video processing.
- **Icon Overlay**: Optionally overlay an icon on your video.

Use **JSON presets** to run the script easily and efficiently.

## Requirements

- Windows PowerShell 5.1
- FFmpeg available in `PATH` (or update `$FFMPEG` in `make-video.ps1`)

FFmpeg 8+ may print a deprecation warning if legacy filter script flags are used. This project uses `-/filter_complex` for filter script files.

## Quick Start

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

## Preset Format (JSON)

A preset is a JSON object with keys matching `make-video.ps1` parameters.

### Main Keys

- `InFile` (string) — Input video file path
- `OutFile` (string) — Output video file path
- `T1` (string) — Start time (FFmpeg format, e.g. `00:12:34.500`)
- `T2` (string) — End time (FFmpeg format)
- `Title` (string) — Title text
- `Subs` (string) — Path to `.ass`/`.srt` subtitles file; use `""` to skip subtitles

### Advanced Keys

- `LayoutMode` ("FIT" | "CROP") — Mode to determine how the video is processed
- `SrcCropL` (int) — Left crop amount in pixels
- `SrcCropR` (int) — Right crop amount in pixels

- `TopBarH` (int) — Height of the top title bar
- `TopBarColor` (string) — Background color of the top bar (e.g., `0xD9D9D9`)
- `TopBarAlpha` (number) — Transparency of the top bar background (0..1)

- `HeaderOffset_CROP` (int) — Offset from the header to the video for CROP mode
- `VideoBottomOffset_CROP` (int) — Offset from the video to the subtitles for CROP mode

- `TitleColor` (string) — Color of the title text (e.g., `blue`)
- `TitleOutlineW` (int) — Outline width of the title text in pixels
- `TitleOutlineColor` (string) — Color of the title text outline
- `TitleOutlineAlpha` (number) — Transparency of the title outline (0..1)
- `FontFile` (string) — Path to the font file to be used for title and subtitles
- `TitleSize` (int) — Font size for the title text

- `SubBgColor` (string) — Background color for subtitles
- `SubBgAlpha` (number) — Transparency of the subtitles background (0..1)
- `SubForceStyle` (string) — Formatting style for subtitles

- `IconFile` (string) — Path to an icon file; set to `""` to disable the icon overlay

### Notes

- If a preset contains **relative paths**, they are resolved under the current working directory.
  - When using `run-preset.ps1`, the working directory is set to the script folder.
- If you want to keep assets under `Data/In` and outputs under `Data/Out`, specify them explicitly in your preset, e.g.:
  - `"InFile": "Data/In/big_video.avi"`
  - `"Subs": "Data/In/subs.ass"`
  - `"OutFile": "Data/Out/clip.mp4"`
- In JSON on Windows, prefer using forward slashes in paths (e.g. `C:/Windows/Fonts/arialbd.ttf`) to avoid escaping backslashes.

## Project Files

- `make-video.ps1` — Main FFmpeg pipeline script
- `run-preset.ps1` — Reads a JSON preset and runs `make-video.ps1` with those parameters
- `run-preset-pause.ps1` — Same as `run-preset.ps1`, but waits for a key press at the end
- `presetsTest/` — Example presets

## License

MIT. See [LICENSE](LICENSE).