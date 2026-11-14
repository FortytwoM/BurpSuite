$ErrorActionPreference = "Stop"

Write-Host "Building loader.jar..." -ForegroundColor Green

$jarPath = (Get-Command jar -ErrorAction SilentlyContinue).Source
if (-not $jarPath) {
    $javaPath = (Get-Command java -ErrorAction SilentlyContinue).Source
    if (-not $javaPath) {
        Write-Host "Error: Java not found. Please install Java JDK 21 or later." -ForegroundColor Red
        exit 1
    }

    $javaDir = Split-Path -Parent $javaPath

    if ($javaDir -like "*javapath*") {
        $javaHome = $env:JAVA_HOME
        if ($javaHome -and (Test-Path (Join-Path $javaHome "bin\jar.exe"))) {
            $jarPath = Join-Path $javaHome "bin\jar.exe"
        } else {
            $realJavaPath = (Get-Item $javaPath).Target
            if ($realJavaPath) {
                $javaDir = Split-Path -Parent $realJavaPath
            }
            $jarPath = Join-Path $javaDir "jar.exe"
        }
    } else {
        $jarPath = Join-Path $javaDir "jar.exe"
    }

    if (-not (Test-Path $jarPath)) {
        $jarPath = Get-ChildItem -Path "C:\Program Files\Java" -Filter "jar.exe" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if (-not $jarPath) {
            Write-Host "Error: jar.exe not found. Please ensure JDK (not just JRE) is installed." -ForegroundColor Red
            exit 1
        }
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$ASM_VERSION = "9.5"
$ASM_DIR = Join-Path $projectRoot "lib"
$ASM_JAR = Join-Path $ASM_DIR "asm-$ASM_VERSION.jar"
$ASM_TREE_JAR = Join-Path $ASM_DIR "asm-tree-$ASM_VERSION.jar"

function Download-File {
    param([string[]]$Urls, [string]$Destination)
    foreach ($url in $Urls) {
        try {
            Write-Host "Trying: $url" -ForegroundColor Gray
            Invoke-WebRequest -Uri $url -OutFile "$Destination.tmp" -UseBasicParsing -ErrorAction Stop
            Move-Item -Force "$Destination.tmp" $Destination
            return $true
        } catch {
            Remove-Item -Force "$Destination.tmp" -ErrorAction SilentlyContinue
        }
    }
    return $false
}

if (-not (Test-Path $ASM_JAR) -or -not (Test-Path $ASM_TREE_JAR)) {
    Write-Host "Downloading ASM library..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $ASM_DIR | Out-Null

    $ok = Download-File -Destination $ASM_JAR -Urls @(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar",
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar"
    )
    if (-not $ok) {
        Write-Host "Error: Failed to download ASM library from all URLs" -ForegroundColor Red
        exit 1
    }

    $ok = Download-File -Destination $ASM_TREE_JAR -Urls @(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar",
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar"
    )
    if (-not $ok) {
        Write-Host "Error: Failed to download ASM-tree library from all URLs" -ForegroundColor Red
        exit 1
    }

    Write-Host "ASM library downloaded successfully" -ForegroundColor Green
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("loader-build-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
    $manifestPath = Join-Path $tempDir "MANIFEST.MF"
    $manifestContent = "Manifest-Version: 1.0`r`nCan-Retransform-Classes: true`r`nMain-Class: Keygen`r`nPremain-Class: Loader`r`n`r`n"
    Set-Content -Path $manifestPath -Value $manifestContent -NoNewline -Encoding ASCII

    Write-Host "Compiling Java classes..." -ForegroundColor Yellow
    Push-Location (Join-Path $projectRoot "src")
    try {
        & javac --release 21 -cp "$ASM_JAR;$ASM_TREE_JAR" Loader.java Filter.java Keygen.java
        if ($LASTEXITCODE -ne 0) { throw "Compilation failed!" }

        Write-Host "Creating JAR file..." -ForegroundColor Yellow
        & $jarPath cfm "$projectRoot\loader.jar" $manifestPath Loader.class Filter.class Keygen.class
        if ($LASTEXITCODE -ne 0) { throw "JAR creation failed!" }
    } finally {
        Remove-Item "Loader.class", "Filter.class", "Keygen.class" -ErrorAction SilentlyContinue
        Pop-Location
    }

    Write-Host "Adding ASM libraries to JAR..." -ForegroundColor Yellow
    $asmDir = Join-Path $tempDir "asm"
    $asmTreeDir = Join-Path $tempDir "asm-tree"
    New-Item -ItemType Directory -Force -Path $asmDir, $asmTreeDir | Out-Null

    Push-Location $asmDir
    try { & $jarPath xf $ASM_JAR } finally { Pop-Location }
    Push-Location $asmTreeDir
    try { & $jarPath xf $ASM_TREE_JAR } finally { Pop-Location }

    & $jarPath uf "$projectRoot\loader.jar" -C $asmDir .
    if ($LASTEXITCODE -ne 0) { throw "Failed to add ASM classes!" }
    & $jarPath uf "$projectRoot\loader.jar" -C $asmTreeDir .
    if ($LASTEXITCODE -ne 0) { throw "Failed to add ASM-tree classes!" }

    Write-Host "Restoring manifest..." -ForegroundColor Yellow
    & $jarPath ufm "$projectRoot\loader.jar" $manifestPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to restore manifest!" }

    Write-Host "Verifying JAR file..." -ForegroundColor Yellow
    $entries = & $jarPath tf "$projectRoot\loader.jar"
    foreach ($entry in @("META-INF/MANIFEST.MF", "Loader.class", "Filter.class", "Keygen.class")) {
        if ($entries -notcontains $entry) { throw "ERROR: $entry missing in loader.jar!" }
    }
    Write-Host "JAR verified successfully" -ForegroundColor Green
} catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
} finally {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

Write-Host "Done! loader.jar created successfully." -ForegroundColor Green
Write-Host "Contents:" -ForegroundColor Cyan
& $jarPath tf "$projectRoot\loader.jar"
