# Script para configurar variables de entorno de OpenCode permanentemente
# Ejecutar como: .\setup-environment.ps1

param(
    [string]$ApiKey = "",
    [string]$BaseUrl = "https://marc-mi78c7vc-swedencentral.services.ai.azure.com/models",
    [string]$ApiVersion = "2024-05-01-preview"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "OpenCode Environment Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Pedir API Key si no se proporcionó
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    $ApiKeySecure = Read-Host "Ingresa tu KIMI_API_KEY" -AsSecureString
    $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKeySecure))
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "Error: API Key es requerida" -ForegroundColor Red
    exit 1
}

# Configurar variables permanentemente (nivel de usuario)
Write-Host "Configurando variables de entorno..." -ForegroundColor Yellow

[Environment]::SetEnvironmentVariable("KIMI_API_KEY", $ApiKey, "User")
[Environment]::SetEnvironmentVariable("KIMI_BASE_URL", $BaseUrl, "User")
[Environment]::SetEnvironmentVariable("KIMI_API_VERSION", $ApiVersion, "User")

Write-Host ""
Write-Host "✅ Variables configuradas permanentemente:" -ForegroundColor Green
Write-Host "   - KIMI_API_KEY: *** (oculto)" -ForegroundColor Gray
Write-Host "   - KIMI_BASE_URL: $BaseUrl" -ForegroundColor Gray
Write-Host "   - KIMI_API_VERSION: $ApiVersion" -ForegroundColor Gray
Write-Host ""

# Crear symlink al repositorio
Write-Host "Creando symlink al repositorio..." -ForegroundColor Yellow

$repoPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFile = Join-Path $repoPath "opencode.jsonc"
$opencodeConfigDir = "$env:USERPROFILE\.config\opencode"
$targetFile = Join-Path $opencodeConfigDir "opencode.json"

# Verificar que el archivo fuente existe
if (-not (Test-Path $sourceFile)) {
    Write-Host "❌ Error: No se encontró $sourceFile" -ForegroundColor Red
    exit 1
}

# Crear directorio de OpenCode si no existe
New-Item -ItemType Directory -Force -Path $opencodeConfigDir | Out-Null

# Eliminar archivo/symlink anterior si existe
if (Test-Path $targetFile) {
    $item = Get-Item $targetFile
    if ($item.Attributes -match "ReparsePoint") {
        Remove-Item $targetFile -Force
        Write-Host "   Symlink anterior eliminado" -ForegroundColor Gray
    } else {
        $backupPath = "$targetFile.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item $targetFile $backupPath
        Write-Host "   Config anterior respaldado en: $backupPath" -ForegroundColor Gray
    }
}

# Crear symlink (requiere permisos de admin en Windows)
try {
    $absoluteSource = (Resolve-Path $sourceFile).Path
    New-Item -ItemType SymbolicLink -Path $targetFile -Target $absoluteSource -ErrorAction Stop | Out-Null
    Write-Host "✅ Symlink creado:" -ForegroundColor Green
    Write-Host "   $targetFile -> $absoluteSource" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  No se pudo crear symlink (requiere privilegios de admin)" -ForegroundColor Yellow
    Write-Host "   Copiando archivo en su lugar..." -ForegroundColor Gray
    Copy-Item $sourceFile $targetFile -Force
    Write-Host "✅ Archivo copiado:" -ForegroundColor Green
    Write-Host "   $targetFile" -ForegroundColor Gray
    Write-Host "   Nota: Si modificas el repo, recuerda copiar nuevamente" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "🎉 Instalación completada!" -ForegroundColor Green
Write-Host ""
Write-Host "Pasos siguientes:" -ForegroundColor Cyan
Write-Host "   1. Abre una nueva terminal PowerShell (para cargar variables)" -ForegroundColor White
Write-Host "   2. Ejecuta: opencode --version" -ForegroundColor White
Write-Host "   3. Ejecuta: opencode" -ForegroundColor White
Write-Host ""
Write-Host "Estructura:" -ForegroundColor Gray
Write-Host "   Repo (central):     ai-config/opencode.jsonc" -ForegroundColor Gray
Write-Host "   Config (symlink):   ~/.config/opencode/opencode.json" -ForegroundColor Gray
Write-Host "   API Key (segura):   Variables de entorno del sistema" -ForegroundColor Gray
