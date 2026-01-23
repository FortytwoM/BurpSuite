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
        if ($javaHome -and (Test-Path $javaHome)) {
            $jarPath = Join-Path $javaHome "bin\jar.exe"
        } else {
            $javaExe = Get-Command java | Select-Object -ExpandProperty Source
            $realJavaPath = (Get-Item $javaExe).Target
            if ($realJavaPath) {
                $javaDir = Split-Path -Parent $realJavaPath
            }
            $jarPath = Join-Path $javaDir "jar.exe"
        }
    } else {
        $jarPath = Join-Path $javaDir "jar.exe"
    }
    
    if (-not (Test-Path $jarPath)) {
        $jarPath = Get-ChildItem -Path "C:\Program Files\Java" -Filter "jar.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if (-not $jarPath) {
            Write-Host "Error: jar.exe not found. Please ensure JDK (not just JRE) is installed." -ForegroundColor Red
            Write-Host "Java found at: $javaPath" -ForegroundColor Yellow
            Write-Host "Searched in: $javaDir" -ForegroundColor Yellow
            exit 1
        }
    }
}

$ASM_VERSION = "9.5"
$ASM_DIR = ".\lib"
$ASM_JAR = "$ASM_DIR\asm-$ASM_VERSION.jar"
$ASM_TREE_JAR = "$ASM_DIR\asm-tree-$ASM_VERSION.jar"

if (-not (Test-Path $ASM_JAR)) {
    Write-Host "Downloading ASM library..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $ASM_DIR | Out-Null
    $ASM_URLS = @(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar",
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm/$ASM_VERSION/asm-$ASM_VERSION.jar"
    )
    $ASM_TREE_URLS = @(
        "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar",
        "https://repo1.maven.org/maven2/org/objectweb/asm/asm-tree/$ASM_VERSION/asm-tree-$ASM_VERSION.jar"
    )
    
    $downloaded = $false
    foreach ($url in $ASM_URLS) {
        try {
            Write-Host "Trying: $url" -ForegroundColor Gray
            Invoke-WebRequest -Uri $url -OutFile $ASM_JAR -UseBasicParsing -ErrorAction Stop
            $downloaded = $true
            break
        }
        catch {
            continue
        }
    }
    
    if (-not $downloaded) {
        Write-Host "Error: Failed to download ASM library from all URLs" -ForegroundColor Red
        exit 1
    }
    
    $downloaded = $false
    foreach ($url in $ASM_TREE_URLS) {
        try {
            Write-Host "Trying: $url" -ForegroundColor Gray
            Invoke-WebRequest -Uri $url -OutFile $ASM_TREE_JAR -UseBasicParsing -ErrorAction Stop
            $downloaded = $true
            break
        }
        catch {
            continue
        }
    }
    
    if (-not $downloaded) {
        Write-Host "Error: Failed to download ASM-tree library from all URLs" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "ASM library downloaded successfully" -ForegroundColor Green
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$manifestDir = Join-Path $projectRoot "META-INF"
$manifestPath = Join-Path $manifestDir "MANIFEST.MF"

if (-not (Test-Path $manifestPath)) {
    Write-Host "Creating MANIFEST.MF..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
    $manifestContent = @"
Manifest-Version: 1.0
Can-Retransform-Classes: true
Main-Class: Keygen
Premain-Class: Loader

"@
    Set-Content -Path $manifestPath -Value $manifestContent -NoNewline
}

Set-Location src

Write-Host "Compiling Java classes..." -ForegroundColor Yellow
javac --release 21 -cp "..\$ASM_JAR;..\$ASM_TREE_JAR" Loader.java Filter.java Keygen.java
if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Creating JAR file..." -ForegroundColor Yellow
& $jarPath cfm ..\loader.jar $manifestPath Loader.class Filter.class Keygen.class
if ($LASTEXITCODE -ne 0) {
    Write-Host "JAR creation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Verifying JAR file..." -ForegroundColor Yellow
$jarContents = & $jarPath tf ..\loader.jar 2>&1 | Out-String
if ($jarContents -notmatch "META-INF/MANIFEST.MF") {
    Write-Host "ERROR: MANIFEST.MF not found in JAR!" -ForegroundColor Red
    Write-Host "JAR contents:" -ForegroundColor Yellow
    Write-Host $jarContents
    exit 1
}
if ($jarContents -notmatch "Loader.class") {
    Write-Host "ERROR: Loader.class not found in JAR!" -ForegroundColor Red
    exit 1
}
Write-Host "JAR file verified successfully" -ForegroundColor Green

cd ..

Write-Host "Cleaning up compiled classes..." -ForegroundColor Yellow
Remove-Item src\Loader.class, src\Filter.class, src\Keygen.class -ErrorAction SilentlyContinue

Write-Host "Adding ASM libraries to JAR..." -ForegroundColor Yellow
$tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
Expand-Archive -Path $ASM_JAR -DestinationPath "$tempDir\asm" -Force
Expand-Archive -Path $ASM_TREE_JAR -DestinationPath "$tempDir\asm-tree" -Force

Write-Host "Backing up manifest..." -ForegroundColor Gray
$manifestBackup = "$tempDir\MANIFEST.MF"
& $jarPath xf loader.jar META-INF/MANIFEST.MF 2>&1 | Out-Null
if (Test-Path "META-INF\MANIFEST.MF") {
    Copy-Item "META-INF\MANIFEST.MF" $manifestBackup -Force
    Remove-Item -Recurse -Force "META-INF" -ErrorAction SilentlyContinue
} else {
    Copy-Item $manifestPath $manifestBackup -Force
}

Write-Host "Adding ASM classes..." -ForegroundColor Gray
& $jarPath uf loader.jar -C "$tempDir\asm" . 2>&1 | Out-Null
& $jarPath uf loader.jar -C "$tempDir\asm-tree" . 2>&1 | Out-Null

Write-Host "Restoring manifest..." -ForegroundColor Gray
& $jarPath ufm loader.jar $manifestBackup 2>&1 | Out-Null

Remove-Item -Recurse -Force $tempDir

Write-Host "Verifying final JAR..." -ForegroundColor Yellow
$finalCheck = & $jarPath tf loader.jar 2>&1 | Out-String
if ($finalCheck -notmatch "META-INF/MANIFEST.MF") {
    Write-Host "ERROR: MANIFEST.MF missing in final JAR!" -ForegroundColor Red
    exit 1
}

Write-Host "Done! loader.jar created successfully." -ForegroundColor Green
Write-Host "Contents:" -ForegroundColor Cyan
& $jarPath tf loader.jar | Select-Object -First 10

