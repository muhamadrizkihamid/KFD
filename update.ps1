# KFD — Kimid Falacy Done
# Update script: pull latest KFD + patch initialized projects
# Usage:
#   .\update.ps1                         — update global only
#   .\update.ps1 -Project C:\myapp       — update global + patch project
#   .\update.ps1 -SkipPull               — skip git pull (offline)

param(
    [string]$Project  = "",
    [switch]$SkipPull
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $HOME '.claude'

# ── Header ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "    K F D   -   Kimid Falacy Done" -ForegroundColor Cyan
Write-Host "    Update / Patch Tool" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Git pull ──────────────────────────────────────────────────────────
if (-not $SkipPull) {
    Write-Host "  Pulling latest KFD from GitHub..." -ForegroundColor White

    # Check for local modifications before pulling
    $gitStatus = git -C $ScriptDir status --porcelain 2>$null
    if ($gitStatus) {
        Write-Host "  [!] Working tree has local changes — skipping git pull." -ForegroundColor Yellow
        Write-Host "      Commit or stash your changes first, or use -SkipPull." -ForegroundColor DarkGray
        Write-Host ""
    } else {
        try {
            git -C $ScriptDir pull --ff-only 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
            Write-Host "  [OK] Pulled latest from origin/main" -ForegroundColor Green
        } catch {
            Write-Host "  [!] git pull failed — continuing with local version." -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# ── Step 2: Verify Claude Code is installed ───────────────────────────────────
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "  [X] ~/.claude not found. Install Claude Code first." -ForegroundColor Red
    exit 1
}

# ── Step 3: Update global ~/.claude/ files ────────────────────────────────────
Write-Host "  Updating global KFD files..." -ForegroundColor White

# Commands
$CmdDest = Join-Path $ClaudeDir 'commands\kfd'
New-Item -ItemType Directory -Force -Path $CmdDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'commands\kfd\*.md') $CmdDest
Write-Host "  [OK] Commands updated  (commands/kfd/)" -ForegroundColor Green

# Agents
$AgentDest = Join-Path $ClaudeDir 'agents'
New-Item -ItemType Directory -Force -Path $AgentDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'agents\squad-*.md') $AgentDest
Write-Host "  [OK] Agents updated    (agents/squad-*.md)" -ForegroundColor Green

# Templates
$LibDest      = Join-Path $ClaudeDir 'kfd\lib'
$SteeringDest = Join-Path $ClaudeDir 'kfd\steering'
$ProcessDest  = Join-Path $ClaudeDir 'kfd\process'
New-Item -ItemType Directory -Force -Path $LibDest, $SteeringDest, $ProcessDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'templates\lib\*.sh')      $LibDest
Copy-Item -Force (Join-Path $ScriptDir 'templates\steering\*.md') $SteeringDest
Copy-Item -Force (Join-Path $ScriptDir 'templates\process\*.md')  $ProcessDest
Write-Host "  [OK] Templates updated (lib/, steering/, process/)" -ForegroundColor Green

# Capture current version and write to global marker
$KfdVersion = git -C $ScriptDir rev-parse --short HEAD 2>$null
if (-not $KfdVersion) { $KfdVersion = "unknown" }
Set-Content -Path (Join-Path $ClaudeDir 'kfd\.kfd-version') -Value $KfdVersion -Encoding utf8

Write-Host ""
Write-Host "  Global update done. (version: $KfdVersion)" -ForegroundColor Cyan
Write-Host ""

# ── Step 4: Project patch (optional) ─────────────────────────────────────────
if (-not $Project) {
    Write-Host "  Patch an initialized project? (leave blank to skip)" -ForegroundColor White
    $Project = Read-Host "  Project path"
    $Project = $Project.Trim().Trim('"')
}

if (-not $Project) {
    Write-Host ""
    Write-Host "  Skipped project patch." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  To patch a project later, run:" -ForegroundColor DarkGray
    Write-Host "    .\update.ps1 -Project <path-to-project>" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Validate project path
$AgentSquadDir = Join-Path $Project '.agent-squad'
if (-not (Test-Path $AgentSquadDir)) {
    Write-Host ""
    Write-Host "  [X] .agent-squad/ not found in: $Project" -ForegroundColor Red
    Write-Host "      Run /kfd:init in that project first." -ForegroundColor DarkGray
    exit 1
}

Write-Host ""
Write-Host "  Patching project: $Project" -ForegroundColor White

# Create backup of files about to be overwritten
$Timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir   = Join-Path $AgentSquadDir ".kfd-backup\$Timestamp"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$SafeFiles = @(
    (Join-Path $AgentSquadDir 'lib'),
    (Join-Path $AgentSquadDir 'process'),
    (Join-Path $AgentSquadDir 'steering\security.md'),
    (Join-Path $AgentSquadDir 'steering\testing.md')
)

foreach ($item in $SafeFiles) {
    if (Test-Path $item) {
        $dest = Join-Path $BackupDir (Split-Path $item -Leaf)
        Copy-Item -Recurse -Force $item $dest
    }
}
Write-Host "  [OK] Backup saved → .agent-squad/.kfd-backup/$Timestamp/" -ForegroundColor DarkGray

# Patch: lib
$ProjLib = Join-Path $AgentSquadDir 'lib'
New-Item -ItemType Directory -Force -Path $ProjLib | Out-Null
Copy-Item -Force (Join-Path $LibDest '*.sh') $ProjLib
Write-Host "  [OK] lib/         patched (jira.sh, git-remote.sh)" -ForegroundColor Green

# Patch: process
$ProjProcess = Join-Path $AgentSquadDir 'process'
New-Item -ItemType Directory -Force -Path $ProjProcess | Out-Null
Copy-Item -Force (Join-Path $ProcessDest '*.md') $ProjProcess
Write-Host "  [OK] process/     patched (SPRINT_MODES, SCRUM_MASTER_PROCESS)" -ForegroundColor Green

# Patch: steering (static templates only — NOT product/tech/structure)
$ProjSteering = Join-Path $AgentSquadDir 'steering'
Copy-Item -Force (Join-Path $SteeringDest 'security.md') $ProjSteering
Copy-Item -Force (Join-Path $SteeringDest 'testing.md')  $ProjSteering
Write-Host "  [OK] steering/    patched (security.md, testing.md)" -ForegroundColor Green
Write-Host "  [--] steering/    kept    (product.md, tech.md, structure.md — project config)" -ForegroundColor DarkGray

# Write version marker
$VersionFile = Join-Path $AgentSquadDir '.kfd-version'
Set-Content -Path $VersionFile -Value $KfdVersion -Encoding utf8
Write-Host "  [OK] .kfd-version written ($KfdVersion)" -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  KFD updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Global : ~/.claude/commands/kfd/ + agents/ + templates/" -ForegroundColor White
Write-Host "  Project: $Project" -ForegroundColor White
Write-Host "  Version: $KfdVersion" -ForegroundColor White
Write-Host ""
Write-Host "  Backup of overwritten files:" -ForegroundColor DarkGray
Write-Host "  .agent-squad/.kfd-backup/$Timestamp/" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
