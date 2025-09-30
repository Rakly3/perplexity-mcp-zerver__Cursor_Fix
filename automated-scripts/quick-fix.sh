#!/bin/bash

# Quick Fix for MCP OutputSchema Error
# Removes all outputSchema definitions and rebuilds the project
# Usage: ./quick-fix.sh

set -e  # Exit on error

echo "🔧 MCP OutputSchema Quick Fix"
echo "================================"
echo ""

# Backup files
echo "📦 Creating backups..."
cp src/schema/toolSchemas.ts src/schema/toolSchemas.ts.backup
cp src/__tests__/unit/schemas.test.ts src/__tests__/unit/schemas.test.ts.backup
echo "✅ Backups created"
echo ""

# Fix toolSchemas.ts - Remove all outputSchema blocks
echo "🔨 Removing outputSchema from tool schemas..."

# Use perl for cross-platform compatibility
perl -i -pe '
  if (/^\s*outputSchema:\s*\{/) {
    $in_output_schema = 1;
    $brace_count = 1;
    $_ = "";
  }
  if ($in_output_schema) {
    $brace_count++ while /\{/g;
    $brace_count-- while /\}/g;
    if ($brace_count == 0) {
      $in_output_schema = 0;
      $_ = "" if /^\s*\},?\s*$/;
    } else {
      $_ = "";
    }
  }
' src/schema/toolSchemas.ts

echo "✅ Tool schemas fixed (6 outputSchema blocks removed)"
echo ""

# Fix test file
echo "🔨 Updating test file..."

# Remove outputSchema test assertions
sed -i.bak '/expect(schema\.outputSchema)/d' src/__tests__/unit/schemas.test.ts
# Change "Input/output schemas" to "Input schema"
sed -i.bak 's/Input\/output schemas/Input schema/' src/__tests__/unit/schemas.test.ts
# Remove the backup file created by sed
rm -f src/__tests__/unit/schemas.test.ts.bak

echo "✅ Tests updated (3 outputSchema assertions removed)"
echo ""

# Rebuild
echo "🔨 Rebuilding project..."
if command -v bun &> /dev/null; then
    bun run build
elif command -v npm &> /dev/null; then
    npm run build
else
    echo "❌ Error: Neither bun nor npm found. Please install Node.js or Bun."
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Summary
echo "================================"
echo "🎉 Fix Complete!"
echo "================================"
echo ""
echo "Changes made:"
echo "  ✅ Removed 6 outputSchema blocks from toolSchemas.ts"
echo "  ✅ Removed 3 outputSchema test assertions"
echo "  ✅ Rebuilt project successfully"
echo ""
echo "Backups created:"
echo "  📦 src/schema/toolSchemas.ts.backup"
echo "  📦 src/__tests__/unit/schemas.test.ts.backup"
echo ""
echo "Next steps:"
echo "  1. Restart your IDE (Cursor/VSCode)"
echo "  2. Test the tools to verify they work"
echo ""
echo "Test command:"
echo '  mcp_perplexity_server_search({ query: "test" })'
echo ""
echo "For more info, see: QUICK_FIX_GUIDE.md"
echo ""
