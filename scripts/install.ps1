param(
  [ValidateSet("project", "cursor", "codex", "claude", "all")]
  [string]$Mode = "project",

  [string]$ProjectPath = (Get-Location).Path,

  [switch]$Update,

  [string]$RepoUrl = "",

  [string]$Branch = "",

  [string]$CodexHome = "",

  [string]$ClaudeHome = ""
)

$ErrorActionPreference = "Stop"

if (-not $RepoUrl) {
  $RepoUrl = if ($env:LAMMUON_AGENT_REPO) { $env:LAMMUON_AGENT_REPO } else { "https://github.com/nShieldSolo/AgentTeam" }
}

if (-not $Branch) {
  $Branch = if ($env:LAMMUON_AGENT_BRANCH) { $env:LAMMUON_AGENT_BRANCH } else { "main" }
}

if (-not $CodexHome) {
  $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
}

if (-not $ClaudeHome) {
  $ClaudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME ".claude" }
}

$script:Installed = 0
$script:Updated = 0
$script:Unchanged = 0
$script:BackedUp = 0

function Reset-Stats {
  $script:Installed = 0
  $script:Updated = 0
  $script:Unchanged = 0
  $script:BackedUp = 0
}

function Test-SameFile {
  param(
    [string]$Source,
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Destination)) {
    return $false
  }

  $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
  $destHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
  return $sourceHash -eq $destHash
}

function Sync-File {
  param(
    [string]$Source,
    [string]$Destination,
    [string]$Stamp
  )

  $destDir = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null

  if (Test-Path -LiteralPath $Destination) {
    if (Test-SameFile -Source $Source -Destination $Destination) {
      $script:Unchanged++
      return
    }

    Copy-Item -LiteralPath $Destination -Destination "$Destination.bak.$Stamp" -Force
    $script:BackedUp++
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    $script:Updated++
    return
  }

  Copy-Item -LiteralPath $Source -Destination $Destination -Force
  $script:Installed++
}

function Get-SourceRevision {
  param([string]$SourceDir)

  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($null -eq $git) {
    return "unknown"
  }

  try {
    git -C $SourceDir rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -eq 0) {
      $rev = (git -C $SourceDir rev-parse HEAD 2>$null).Trim()
      if ($rev) {
        git -C $SourceDir diff --quiet -- . *> $null
        $dirtyWorktree = $LASTEXITCODE -ne 0
        git -C $SourceDir diff --cached --quiet -- . *> $null
        $dirtyIndex = $LASTEXITCODE -ne 0
        if ($dirtyWorktree -or $dirtyIndex) {
          return "$rev-dirty"
        }
        return $rev
      }
    }
  } catch {
    # Fall through to remote lookup.
  }

  try {
    $line = git ls-remote $RepoUrl "refs/heads/$Branch" 2>$null | Select-Object -First 1
    if ($line) {
      return ($line -split "\s+")[0]
    }
  } catch {
    # Fall through to unknown.
  }

  return "unknown"
}

function Write-State {
  param(
    [string]$StateFile,
    [string]$SourceDir,
    [string]$Scope
  )

  $stateDir = Split-Path -Parent $StateFile
  New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

  $revision = Get-SourceRevision -SourceDir $SourceDir
  $installedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $content = @(
    "scope=$Scope",
    "repo_url=$RepoUrl",
    "branch=$Branch",
    "revision=$revision",
    "installed_at=$installedAt"
  )

  Set-Content -LiteralPath $StateFile -Value $content -Encoding UTF8
}

function Print-Summary {
  param(
    [string]$Label,
    [string]$Location,
    [string]$StateFile
  )

  $total = $script:Installed + $script:Updated + $script:Unchanged
  Write-Host "$Label`: $Location"
  Write-Host "Files: $total total, $script:Installed new, $script:Updated updated, $script:Unchanged unchanged, $script:BackedUp backed up"
  Write-Host "State: $StateFile"
}

function Sync-Project {
  param([string]$SourceDir, [string]$TargetDir)

  Reset-Stats
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $agentsDir = Join-Path $TargetDir ".cursor\agents"
  $rulesDir = Join-Path $TargetDir ".cursor\rules"
  $stateFile = Join-Path $TargetDir ".cursor\lammuon-agent.state"

  New-Item -ItemType Directory -Force -Path $agentsDir, $rulesDir | Out-Null

  Get-ChildItem -LiteralPath (Join-Path $SourceDir ".cursor\agents") -Filter "lammuon-*.md" -File | ForEach-Object {
    Sync-File -Source $_.FullName -Destination (Join-Path $agentsDir $_.Name) -Stamp $stamp
  }

  Get-ChildItem -LiteralPath (Join-Path $SourceDir ".cursor\rules") -Filter "lammuon-*.mdc" -File | ForEach-Object {
    Sync-File -Source $_.FullName -Destination (Join-Path $rulesDir $_.Name) -Stamp $stamp
  }

  if (($script:Installed + $script:Updated + $script:Unchanged) -eq 0) {
    throw "No lammuon agent/rule files found in source: $SourceDir"
  }

  Write-State -StateFile $stateFile -SourceDir $SourceDir -Scope "project"
  Print-Summary -Label "Synced lammuon project files" -Location (Join-Path $TargetDir ".cursor") -StateFile $stateFile
  Write-Host "Restart Cursor or reload the window if the agents/rules do not appear immediately."
}

function Sync-CursorGlobal {
  param([string]$SourceDir)

  Reset-Stats
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $targetDir = Join-Path $HOME ".cursor\agents"
  $stateFile = Join-Path $targetDir ".lammuon-agent.state"

  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  Get-ChildItem -LiteralPath (Join-Path $SourceDir ".cursor\agents") -Filter "lammuon-*.md" -File | ForEach-Object {
    Sync-File -Source $_.FullName -Destination (Join-Path $targetDir $_.Name) -Stamp $stamp
  }

  if (($script:Installed + $script:Updated + $script:Unchanged) -eq 0) {
    throw "No lammuon Cursor agents found in source: $SourceDir"
  }

  Write-State -StateFile $stateFile -SourceDir $SourceDir -Scope "cursor-global"
  Print-Summary -Label "Synced Cursor global agents" -Location $targetDir -StateFile $stateFile
  Write-Host ""
  Write-Host "WARNING: Cursor global install only syncs agents (~/.cursor/agents)."
  Write-Host "         It does NOT install .cursor/rules (lammuon-preflight, lammuon-router, ...)."
  Write-Host "         For Router / Test Case / Build gates in a repo, run project install in that repo."
}

function Sync-SkillBundle {
  param(
    [string]$SourceDir,
    [string]$SkillSrc,
    [string]$SkillDest,
    [string]$Scope,
    [string]$RestartHint
  )

  Reset-Stats
  $stamp = Get-Date -Format "yyyyMMddHHmmss"
  $stateFile = Join-Path $SkillDest ".lammuon-agent.state"

  if (-not (Test-Path -LiteralPath (Join-Path $SkillSrc "SKILL.md"))) {
    throw "Skill source not found: $(Join-Path $SkillSrc 'SKILL.md')"
  }

  New-Item -ItemType Directory -Force -Path `
    (Join-Path $SkillDest "references\.cursor\agents"), `
    (Join-Path $SkillDest "references\.cursor\rules") | Out-Null

  Sync-File -Source (Join-Path $SkillSrc "SKILL.md") -Destination (Join-Path $SkillDest "SKILL.md") -Stamp $stamp

  Get-ChildItem -LiteralPath (Join-Path $SourceDir ".cursor\agents") -Filter "lammuon-*.md" -File | ForEach-Object {
    Sync-File -Source $_.FullName -Destination (Join-Path $SkillDest "references\.cursor\agents\$($_.Name)") -Stamp $stamp
  }

  Get-ChildItem -LiteralPath (Join-Path $SourceDir ".cursor\rules") -Filter "lammuon-*.mdc" -File | ForEach-Object {
    Sync-File -Source $_.FullName -Destination (Join-Path $SkillDest "references\.cursor\rules\$($_.Name)") -Stamp $stamp
  }

  Write-State -StateFile $stateFile -SourceDir $SourceDir -Scope $Scope
  Print-Summary -Label "Synced skill ($Scope)" -Location $SkillDest -StateFile $stateFile
  Write-Host $RestartHint
}

function Sync-CodexGlobal {
  param([string]$SourceDir)

  $skillSrc = Join-Path $SourceDir "codex\skills\lammuon-team"
  $skillDest = Join-Path $CodexHome "skills\lammuon-team"
  Sync-SkillBundle -SourceDir $SourceDir -SkillSrc $skillSrc -SkillDest $skillDest -Scope "codex-global" `
    -RestartHint "Restart Codex if the skill is not listed immediately."
}

function Sync-ClaudeGlobal {
  param([string]$SourceDir)

  $skillSrc = Join-Path $SourceDir "codex\skills\lammuon-team"
  $skillDest = Join-Path $ClaudeHome "skills\lammuon-team"
  Sync-SkillBundle -SourceDir $SourceDir -SkillSrc $skillSrc -SkillDest $skillDest -Scope "claude-global" `
    -RestartHint "Restart Claude Code if /lammuon-team is not listed immediately."
}

function Install-FromSource {
  param([string]$SourceDir)

  switch ($Mode) {
    "project" { Sync-Project -SourceDir $SourceDir -TargetDir $ProjectPath }
    "cursor" { Sync-CursorGlobal -SourceDir $SourceDir }
    "codex" { Sync-CodexGlobal -SourceDir $SourceDir }
    "claude" { Sync-ClaudeGlobal -SourceDir $SourceDir }
    "all" {
      Sync-CursorGlobal -SourceDir $SourceDir
      Sync-CodexGlobal -SourceDir $SourceDir
      Sync-ClaudeGlobal -SourceDir $SourceDir
      Write-Host ""
      Write-Host "Global all complete: Cursor + Codex + Claude."
      Write-Host "Cursor global = agents only. For project rules (.cursor/rules), run project install in each repo."
    }
  }
}

$localSource = $null
if ($PSScriptRoot) {
  $candidate = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..") -ErrorAction SilentlyContinue
  if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate.Path ".cursor"))) {
    $localSource = $candidate.Path
  }
}

if ($localSource) {
  Install-FromSource -SourceDir $localSource
  exit 0
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("lammuon-agent-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
  $archiveUrl = "$RepoUrl/archive/refs/heads/$Branch.zip"
  $archivePath = Join-Path $tempDir "source.zip"
  Write-Host "Downloading $archiveUrl"
  Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath
  Expand-Archive -LiteralPath $archivePath -DestinationPath $tempDir -Force

  $sourceDir = Get-ChildItem -LiteralPath $tempDir -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName ".cursor")
  } | Select-Object -First 1

  if (-not $sourceDir) {
    throw "Downloaded archive does not contain .cursor. Check repo/branch."
  }

  Install-FromSource -SourceDir $sourceDir.FullName
} finally {
  Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
