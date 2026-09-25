<#
  Menyamakan salinan Wallet di laptop dengan GitHub (sumber kebenaran).

  Pemakaian (PowerShell):
    powershell -ExecutionPolicy Bypass -File .\tool\sinkron-lokal.ps1
  atau dengan folder lain:
    powershell -ExecutionPolicy Bypass -File .\tool\sinkron-lokal.ps1 -Folder "D:\kode\wallet"

  Aman dijalankan berulang kali:
  - Folder bersih di cabang main  -> cukup ditarik (git pull), tanpa menyentuh apa pun.
  - Ada perubahan lokal / cabang lain / bukan repo git -> folder lama TIDAK dihapus,
    tetapi dipindah ke "<nama>-lama-<tanggal>" lalu salinan bersih di-clone ulang.
  - Berkas data pribadi yang tidak ada di GitHub (assets/seed/my_data.json, *.mmbak)
    disalin dari folder lama ke folder baru.
#>
param(
  [string]$Folder = "C:\Users\T6N0CV02S35823C\Github\wallet",
  [string]$Repo = "https://github.com/irsyadmsk/wallet.git"
)

$ErrorActionPreference = "Stop"

function Clone-Fresh {
  Write-Host "Meng-clone salinan bersih ke $Folder ..." -ForegroundColor Cyan
  git clone $Repo $Folder
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "Git belum terpasang. Pasang dari https://git-scm.com/download/win lalu jalankan ulang."
}

$old = $null
if (Test-Path (Join-Path $Folder ".git")) {
  Push-Location $Folder
  git fetch origin --prune
  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  $dirty = (git status --porcelain)
  $ahead = (git rev-list --count origin/main..HEAD).Trim()
  Pop-Location

  if ($branch -eq "main" -and -not $dirty -and $ahead -eq "0") {
    Push-Location $Folder
    git pull --ff-only origin main
    Pop-Location
    Write-Host "Sudah sama dengan GitHub (main)." -ForegroundColor Green
  } else {
    $old = "$Folder-lama-$(Get-Date -Format 'yyyyMMdd-HHmm')"
    Write-Host "Ada perubahan lokal atau cabang lain ($branch). Folder lama disimpan sebagai:`n  $old" -ForegroundColor Yellow
    Rename-Item -Path $Folder -NewName (Split-Path $old -Leaf)
    Clone-Fresh
  }
} elseif (Test-Path $Folder) {
  $old = "$Folder-lama-$(Get-Date -Format 'yyyyMMdd-HHmm')"
  Write-Host "Folder ada tetapi bukan repo git. Disimpan sebagai:`n  $old" -ForegroundColor Yellow
  Rename-Item -Path $Folder -NewName (Split-Path $old -Leaf)
  Clone-Fresh
} else {
  Clone-Fresh
}

# Data pribadi yang sengaja tidak di-commit: bawa dari folder lama bila ada.
if ($old) {
  $seed = Join-Path $old "assets\seed\my_data.json"
  if (Test-Path $seed) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Folder "assets\seed") | Out-Null
    Copy-Item $seed (Join-Path $Folder "assets\seed\my_data.json")
    Write-Host "Disalin: assets\seed\my_data.json" -ForegroundColor Gray
  }
  Get-ChildItem -Path $old -Filter *.mmbak -File -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $Folder $_.Name)
    Write-Host "Disalin: $($_.Name)" -ForegroundColor Gray
  }
}

if (Get-Command flutter -ErrorAction SilentlyContinue) {
  Push-Location $Folder
  flutter pub get
  Pop-Location
}

Push-Location $Folder
Write-Host "`nVersi di laptop sekarang:" -ForegroundColor Green
git log --oneline -1
Pop-Location
