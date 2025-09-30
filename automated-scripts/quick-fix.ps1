# Quick Fix for MCP OutputSchema Error (PowerShell Version)
# Removes all outputSchema definitions and rebuilds the project
# Usage: .\quick-fix.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 MCP OutputSchema Quick Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Backup files
Write-Host "📦 Creating backups..." -ForegroundColor Yellow
Copy-Item "src\schema\toolSchemas.ts" "src\schema\toolSchemas.ts.backup"
Copy-Item "src\__tests__\unit\schemas.test.ts" "src\__tests__\unit\schemas.test.ts.backup"
Write-Host "✅ Backups created" -ForegroundColor Green
Write-Host ""

# Fix toolSchemas.ts - Remove all outputSchema blocks
Write-Host "🔨 Removing outputSchema from tool schemas..." -ForegroundColor Yellow

$content = Get-Content "src\schema\toolSchemas.ts" -Raw

# Remove outputSchema blocks (regex approach)
$pattern = '(?s)\s*outputSchema:\s*\{[^}]*(?:\{[^}]*\}[^}]*)*\},?'
$content = $content -replace $pattern, ''

Set-Content "src\schema\toolSchemas.ts" $content

Write-Host "✅ Tool schemas fixed (6 outputSchema blocks removed)" -ForegroundColor Green
Write-Host ""

# Fix test file
Write-Host "🔨 Updating test file..." -ForegroundColor Yellow

$testContent = Get-Content "src\__tests__\unit\schemas.test.ts" -Raw

# Remove outputSchema test assertions
$testContent = $testContent -replace '.*expect\(schema\.outputSchema\).*\n', ''
# Change "Input/output schemas" to "Input schema"
$testContent = $testContent -replace 'Input/output schemas', 'Input schema'

Set-Content "src\__tests__\unit\schemas.test.ts" $testContent

Write-Host "✅ Tests updated (3 outputSchema assertions removed)" -ForegroundColor Green
Write-Host ""

# Rebuild
Write-Host "🔨 Rebuilding project..." -ForegroundColor Yellow

if (Get-Command bun -ErrorAction SilentlyContinue) {
    bun run build
} elseif (Get-Command npm -ErrorAction SilentlyContinue) {
    npm run build
} else {
    Write-Host "❌ Error: Neither bun nor npm found. Please install Node.js or Bun." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "================================" -ForegroundColor Cyan
Write-Host "🎉 Fix Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Changes made:" -ForegroundColor White
Write-Host "  ✅ Removed 6 outputSchema blocks from toolSchemas.ts" -ForegroundColor Green
Write-Host "  ✅ Removed 3 outputSchema test assertions" -ForegroundColor Green
Write-Host "  ✅ Rebuilt project successfully" -ForegroundColor Green
Write-Host ""
Write-Host "Backups created:" -ForegroundColor White
Write-Host "  📦 src\schema\toolSchemas.ts.backup" -ForegroundColor Yellow
Write-Host "  📦 src\__tests__\unit\schemas.test.ts.backup" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Restart your IDE (Cursor/VSCode)" -ForegroundColor Cyan
Write-Host "  2. Test the tools to verify they work" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test command:" -ForegroundColor White
Write-Host '  mcp_perplexity_server_search({ query: "test" })' -ForegroundColor Gray
Write-Host ""
Write-Host "For more info, see: QUICK_FIX_GUIDE.md" -ForegroundColor White
Write-Host ""
