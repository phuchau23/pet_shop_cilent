# PowerShell script to patch isar_flutter_libs build.gradle
$isarBuildGradle = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle"

if (Test-Path $isarBuildGradle) {
    $content = Get-Content $isarBuildGradle -Raw
    if ($content -notmatch 'namespace = "dev.isar.isar_flutter_libs"') {
        $content = $content -replace '(android \{)', "`$1`n    namespace = `"dev.isar.isar_flutter_libs`""
        Set-Content $isarBuildGradle $content
        Write-Host "✅ Patched isar_flutter_libs build.gradle" -ForegroundColor Green
    } else {
        Write-Host "✅ Already patched" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ isar_flutter_libs build.gradle not found" -ForegroundColor Yellow
}
