#Requires -Version 5.1
[CmdletBinding()]
param(
  # Main parameters (can be passed from outside)
  [Parameter()]
  [string]$InFile = "big_video.mp4",

  [Parameter()]
  [string]$OutFile = "tiktok_clip.mp4",

  # Time values in ffmpeg format (e.g. 00:12:34.500)
  [Parameter()]
  [string]$T1 = "00:12:34.500",

  [Parameter()]
  [string]$T2 = "00:13:10.000",

  [Parameter()]
  [string]$Title = "MY TITLE",

  # Path to .ass/.srt. Leave empty to skip subtitles overlay
  [Parameter()]
  [string]$Subs = "subs_for_clip.ass",

  # Advanced settings (can be moved into presets)
  [Parameter()]
  [ValidateSet("FIT", "CROP")]
  [string]$LayoutMode = "CROP",

  [Parameter()]
  [int]$SrcCropL = 0,

  [Parameter()]
  [int]$SrcCropR = 0,

  [Parameter()]
  [int]$TopBarH = 220,

  [Parameter()]
  [string]$FontFile = "C:\Windows\Fonts\arialbd.ttf",

  [Parameter()]
  [int]$TitleSize = 64,

  [Parameter()]
  [string]$SubForceStyle = "Alignment=2,Fontsize=52,Outline=3,Shadow=0,MarginV=70",


  # Base directories for resolving relative paths.
  # Default is the current working directory.
  # Note: run-preset.ps1 sets the working directory to the script folder.
  [Parameter()]
  [string]$DataInDir = ".",

  [Parameter()]
  [string]$DataOutDir = ".",

  # Icon file name/path (resolved under Data\In if relative)
  [Parameter()]
  [string]$IconFile = "icon.gif"
)

Set-StrictMode -Version Latest

$ErrorActionPreference = "Stop"

# ===================== SETTINGS (edit here) =====================

# Base directories (relative to the *current working directory*)
$Cwd = (Get-Location).Path
$DataInDirResolved = if ([System.IO.Path]::IsPathRooted($DataInDir)) { $DataInDir } else { (Join-Path $Cwd $DataInDir) }
$DataOutDirResolved = if ([System.IO.Path]::IsPathRooted($DataOutDir)) { $DataOutDir } else { (Join-Path $Cwd $DataOutDir) }

function Resolve-UnderDir([string]$path, [string]$baseDir) {
  if ([string]::IsNullOrWhiteSpace($path)) { return $path }
  if ([System.IO.Path]::IsPathRooted($path)) { return $path }
  return (Join-Path $baseDir $path)
}

# Paths
$FFMPEG = "ffmpeg"                 # or "C:\ffmpeg\bin\ffmpeg.exe"
$INPUT  = Resolve-UnderDir $InFile $DataInDirResolved
$OUT    = Resolve-UnderDir $OutFile $DataOutDirResolved

# Trim
# (passed via parameters $T1/$T2)

# Output (TikTok / Shorts)
$OUT_W = 1080
$OUT_H = 1920
$FPS   = 30

# Layout mode: "FIT" (letterbox/pillarbox) or "CROP" (fill frame, center crop)
$LAYOUT_MODE = $LayoutMode          # "FIT" | "CROP"

# Extra crop from the source (left/right), in source pixels
$SRC_CROP_L = $SrcCropL
$SRC_CROP_R = $SrcCropR

# Title
$TITLE        = $Title
$TOP_BAR_H    = $TopBarH
$FONTFILE     = Resolve-UnderDir $FontFile $DataInDirResolved
$TITLE_SIZE   = $TitleSize

# Subtitles (.ass recommended, .srt ok)
$SUBS = Resolve-UnderDir $Subs $DataInDirResolved
$SUB_FORCE_STYLE = $SubForceStyle

# Icon (GIF with transparency)
$ICON        = Resolve-UnderDir $IconFile $DataInDirResolved
$ICON_W      = 240
$ICON_MARGIN = 40
$ICON_DUR    = 2.0      # show during the last N seconds
$ICON_FADE   = 0.35     # fade-in duration, seconds

# Background for FIT mode: "black" or "blur"
$FIT_BG_MODE = "black"

# Encoding
$CRF          = 18
$PRESET       = "medium"
$AUDIO_BITRATE= "160k"

# ===================== INTERNAL LOGIC =====================

function Escape-ForFfmpegText([string]$s) {
  # For drawtext text='...': escape \, ', :, and newlines
  $s = $s -replace "\\", "\\\\"
  $s = $s -replace "'", "\\'"
  $s = $s -replace ":", "\\:"
  $s = $s -replace "`r`n|`n|`r", " "
  return $s
}

function Escape-ForFfmpegPath([string]$p) {
  # In filtergraph it's safer to use / instead of \
  # Also escape the drive letter colon (C:) as C\: because ':' separates options in ffmpeg filter args.
  $p = ($p -replace "\\", "/")
  # Escape the drive letter colon (C:) as C\: because ':' separates options in ffmpeg filter args.
  # We want exactly ONE backslash in the final string: C\:/Windows/Fonts/...
  $p = ($p -replace '^([A-Za-z]):', '$1\:')
  return $p
}

$TitleEsc = Escape-ForFfmpegText $TITLE
$FontEsc  = Escape-ForFfmpegPath $FONTFILE
$IconEsc  = $ICON  # can be passed to -i as-is
$HasIcon = (-not [string]::IsNullOrWhiteSpace($ICON)) -and (Test-Path -LiteralPath $ICON)

$HasSubs = (-not [string]::IsNullOrWhiteSpace($SUBS)) -and (Test-Path -LiteralPath $SUBS)
if ($HasSubs) {
  $SubsEsc = Escape-ForFfmpegPath $SUBS
  $SubsFilter = "[vtitle]subtitles='${SubsEsc}:force_style=${SUB_FORCE_STYLE}'[vsub];"
} else {
  $SubsFilter = "[vtitle]null[vsub];"
}

if ($HasIcon) {
  $IconFilter = @"
[1:v]fps=$FPS,scale=${ICON_W}:-1:flags=lanczos,format=rgba,
fade=t=in:st=0:d=${ICON_FADE}:alpha=1[gif];

[vsub][gif]overlay=
  x=W-w-${ICON_MARGIN}:
  y=H-h-${ICON_MARGIN}:
  enable='between(t,(T-$ICON_DUR),T)'
[vout]
"@
} else {
  # No icon: pass video through
  $IconFilter = "[vsub]null[vout];"
}

# Source crop (L/R)
$SrcCropExpr = "crop=w=iw-($SRC_CROP_L+$SRC_CROP_R):h=ih:x=${SRC_CROP_L}:y=0"

# Layout filter
if ($LAYOUT_MODE -eq "FIT") {
  if ($FIT_BG_MODE -eq "blur") {
    $VideoLayout = @"
[v0]$SrcCropExpr,fps=$FPS,scale=${OUT_W}:${OUT_H}:force_original_aspect_ratio=increase,crop=${OUT_W}:${OUT_H},gblur=sigma=30[bg];
[v0]$SrcCropExpr,fps=$FPS,scale=${OUT_W}:${OUT_H}:force_original_aspect_ratio=decrease[fg];
[bg][fg]overlay=(W-w)/2:(H-h)/2[vlaid];
"@
  } else {
    $VideoLayout = @"
[v0]$SrcCropExpr,fps=$FPS,scale=${OUT_W}:${OUT_H}:force_original_aspect_ratio=decrease,
pad=${OUT_W}:${OUT_H}:(ow-iw)/2:(oh-ih)/2:color=black[vlaid];
"@
  }
} else {
  $VideoLayout = @"
[v0]$SrcCropExpr,fps=$FPS,
scale=${OUT_W}:${OUT_H}:force_original_aspect_ratio=increase,
crop=${OUT_W}:${OUT_H}[vlaid];
"@
}

# Temporary filter script file
$FilterFile = Join-Path $env:TEMP ("ff_filters_{0}.txt" -f ([System.Guid]::NewGuid().ToString("N")))

try {
  $FilterText = @"
[0:v]format=yuv420p[v0];

$VideoLayout

[vlaid]
drawbox=x=0:y=0:w=iw:h=${TOP_BAR_H}:color=black@1:t=fill,
drawtext=fontfile='$FontEsc':text='$TitleEsc':
  x=(w-text_w)/2:y=$TOP_BAR_H/2-text_h/2:
  fontsize=${TITLE_SIZE}:fontcolor=white:
  borderw=2:bordercolor=black@0.6
[vtitle];

$SubsFilter

$IconFilter
"@

  # Write UTF-8 WITHOUT BOM. BOM at the beginning may break ffmpeg filter parsing.
  [System.IO.File]::WriteAllText(
    $FilterFile,
    $FilterText,
    (New-Object System.Text.UTF8Encoding($false))
  )

  # Ensure output directory exists (supports OutFile like "Data/Out/clip.mp4")
  $OutDir = Split-Path -Parent $OUT
  if (-not [string]::IsNullOrWhiteSpace($OutDir) -and -not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  }

  $FfmpegArgs = @(
    '-ss', $T1,
    '-to', $T2,
    '-i', $INPUT
  )



  if ($HasIcon) {
    $FfmpegArgs += @('-ignore_loop', '0', '-i', $IconEsc)
  }

  $FfmpegArgs += @(
    '-/filter_complex', $FilterFile,
    '-map', '[vout]',
    '-map', '0:a?',
    '-c:v', 'libx264',
    '-crf', $CRF,
    '-preset', $PRESET,
    '-pix_fmt', 'yuv420p',
    '-c:a', 'aac',
    '-b:a', $AUDIO_BITRATE,
    '-movflags', '+faststart',
    $OUT
  )

  # Run ffmpeg
  & $FFMPEG @FfmpegArgs
}
finally {
  if (Test-Path -LiteralPath $FilterFile) { Remove-Item -LiteralPath $FilterFile -Force }
}