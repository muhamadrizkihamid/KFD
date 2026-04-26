# KFD — Kimid Falacy Done
# Installer for Windows PowerShell (no bash required)
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
#    or: .\install.ps1   (if execution policy allows)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $HOME '.claude'

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host "    K F D   -   Kimid Falacy Done   v1.0" -ForegroundColor White
Write-Host "    AI-powered sprint framework for Claude Code" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White
Write-Host ""

# Check Claude Code is installed
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "  [X] ~/.claude not found. Install Claude Code first." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Claude Code found"

# Check existing install
$ExistingCmdDir = Join-Path $ClaudeDir 'commands\kfd'
if (Test-Path $ExistingCmdDir) {
    Write-Host "  [!] KFD already installed." -ForegroundColor Yellow
    $confirm = Read-Host "  Update/reinstall? [y/N]"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "  Aborted."
        exit 0
    }
}

Write-Host ""
Write-Host "Installing..." -ForegroundColor White

# Commands
$CmdDest = Join-Path $ClaudeDir 'commands\kfd'
New-Item -ItemType Directory -Force -Path $CmdDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'commands\kfd\*.md') $CmdDest
Write-Host "  [OK] Commands: /kfd:init  /kfd:sprint  /kfd:status"

# Agents
$AgentDest = Join-Path $ClaudeDir 'agents'
New-Item -ItemType Directory -Force -Path $AgentDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'agents\squad-*.md') $AgentDest
Write-Host "  [OK] 7 agents installed (Scrum Master, Architect, Designers, Developers, Security, Tester)"

# Templates
$LibDest      = Join-Path $ClaudeDir 'kfd\lib'
$SteeringDest = Join-Path $ClaudeDir 'kfd\steering'
$ProcessDest  = Join-Path $ClaudeDir 'kfd\process'
New-Item -ItemType Directory -Force -Path $LibDest, $SteeringDest, $ProcessDest | Out-Null
Copy-Item -Force (Join-Path $ScriptDir 'templates\lib\*.sh')      $LibDest
Copy-Item -Force (Join-Path $ScriptDir 'templates\steering\*.md') $SteeringDest
Copy-Item -Force (Join-Path $ScriptDir 'templates\process\*.md')  $ProcessDest
Write-Host "  [OK] Template library installed"

Write-Host ""
Write-Host "KFD installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "How to use in a project:" -ForegroundColor White
Write-Host ""
Write-Host "  /kfd:init    - Setup KFD in a new project" -ForegroundColor Cyan
Write-Host "  /kfd:sprint  - Start a sprint from a Jira issue" -ForegroundColor Cyan
Write-Host "  /kfd:status  - View active sprint status" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: project-level lib (.agent-squad/lib/jira.sh) is frozen at /kfd:init time." -ForegroundColor DarkGray
Write-Host "After updating KFD, refresh per-project libs by copying:" -ForegroundColor DarkGray
Write-Host "  Copy-Item `$HOME\.claude\kfd\lib\*.sh `<project>\.agent-squad\lib\ -Force" -ForegroundColor DarkGray
Write-Host ""
