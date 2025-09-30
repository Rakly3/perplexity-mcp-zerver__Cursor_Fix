# How to Fix the MCP OutputSchema Error in Cursor/VSCode - Complete Guide

> **TL;DR:** Remove all `outputSchema` definitions from your tool schemas, rebuild, and restart Cursor/VSCode. That's it! ✅

## Table of Contents

1. [Quick Start](#quick-start) - Fix it in 5 minutes
2. [What Happened](#what-happened) - Understanding the error
3. [Why It Happened](#why-it-happened) - Root cause analysis
4. [The Fix](#the-fix) - Detailed implementation
5. [Verification](#verification) - Testing the fix
6. [Understanding MCP](#understanding-mcp) - Learn the concepts
7. [Resources](#resources) - Additional documentation

---

## Quick Start

### Error You're Seeing

```
MCP error -32600: Tool [tool_name] has an output schema but did not return structured content
```

### 3-Step Fix (5 Minutes)

#### Step 1: Edit Tool Schemas

Open `src/schema/toolSchemas.ts` and delete all `outputSchema` blocks:

```bash
# Search for this pattern and delete it (6 times):
outputSchema: {
  type: "object",
  properties: { ... }
},
```

#### Step 2: Edit Tests

Open `src/__tests__/unit/schemas.test.ts` and remove these lines:

```typescript
// Line ~30: DELETE
expect(schema.outputSchema).toBeDefined();

// Lines ~115-116: DELETE
expect(schema.outputSchema.type).toBe("object");
expect(schema.outputSchema.properties).toBeDefined();
```

#### Step 3: Rebuild & Restart

```bash
bun run build  # or: npm run build
# Then restart Cursor/VSCode
```

### Done! ✅

Test it:
```typescript
mcp_perplexity_server_search({ query: "test" })
// Should return results instead of error!
```

---

## What Happened

### The Error

All 6 Perplexity MCP tools were failing with the same error:

- ❌ `search`
- ❌ `chat_perplexity`
- ❌ `get_documentation`
- ❌ `find_apis`
- ❌ `check_deprecated_code`
- ❌ `extract_url_content`

### The Message

```
MCP error -32600: Tool has an output schema but did not return structured content
```

### The Impact

- **100% of tools broken**
- Development completely blocked
- No way to test or use any MCP functionality

---

## Why It Happened

### The MCP Protocol Has Two Modes

#### Mode 1: Structured Data (with outputSchema)

When you define `outputSchema`, MCP expects the tool to return **actual structured data**:

```typescript
// Tool schema WITH outputSchema
{
  name: "getWeather",
  outputSchema: {
    type: "object",
    properties: {
      temperature: { type: "number" },
      conditions: { type: "string" }
    }
  }
}

// Tool MUST return:
return { temperature: 72, conditions: "sunny" };  // ✅ Correct

// Tool CANNOT return:
return { content: [{ type: "text", text: "..." }] };  // ❌ Wrong!
```

#### Mode 2: Text Content (without outputSchema)

When you DON'T define `outputSchema`, MCP expects **text content**:

```typescript
// Tool schema WITHOUT outputSchema
{
  name: "search",
  inputSchema: { ... }
  // No outputSchema
}

// Tool returns string, handler wraps it:
return { content: [{ type: "text", text: "result" }] };  // ✅ Correct
```

### Our Problem

We had `outputSchema` (Mode 1) but returned text content (Mode 2):

```typescript
// ❌ MISMATCH:
// Schema said: "Expect structured data"
outputSchema: {
  type: "object",
  properties: { response: { type: "string" } }
}

// But tool returned: text content
return { content: [{ type: "text", text: "..." }] };

// Result: Validation error!
```

### Why Was OutputSchema There?

It was added for **documentation purposes** to describe what the response would contain. But MCP interprets `outputSchema` as a **validation requirement**, not documentation.

---

## The Fix

### Files to Change

1. `src/schema/toolSchemas.ts` - Remove 6 outputSchema blocks
2. `src/__tests__/unit/schemas.test.ts` - Remove 3 test assertions

### Option A: Manual Fix

#### File 1: `src/schema/toolSchemas.ts`

Search for `outputSchema:` and delete **6 blocks**:

**chat_perplexity (lines ~38-52):**
```typescript
outputSchema: {
  type: "object",
  description: "...",
  properties: {
    chat_id: { type: "string", description: "..." },
    response: { type: "string", description: "..." }
  }
},  // ← DELETE entire block including this comma
```

**extract_url_content (lines ~109-159):**
```typescript
outputSchema: {
  type: "object",
  description: "...",
  properties: {
    status: { ... },
    message: { ... },
    rootUrl: { ... },
    explorationDepth: { ... },
    pagesExplored: { ... },
    content: { ... }
  }
},  // ← DELETE entire block including this comma
```

**get_documentation (lines ~204-212):**
```typescript
outputSchema: {
  type: "object",
  properties: {
    response: { type: "string", description: "..." }
  }
},  // ← DELETE entire block including this comma
```

**find_apis (lines ~252-260):**
```typescript
outputSchema: {
  type: "object",
  properties: {
    response: { type: "string", description: "..." }
  }
},  // ← DELETE entire block including this comma
```

**check_deprecated_code (lines ~303-311):**
```typescript
outputSchema: {
  type: "object",
  properties: {
    response: { type: "string", description: "..." }
  }
},  // ← DELETE entire block including this comma
```

**search (lines ~363-371):**
```typescript
outputSchema: {
  type: "object",
  properties: {
    response: { type: "string", description: "..." }
  }
},  // ← DELETE entire block including this comma
```

#### File 2: `src/__tests__/unit/schemas.test.ts`

**Line ~30:**
```typescript
// Before:
expect(schema.inputSchema).toBeDefined();
expect(schema.outputSchema).toBeDefined();  // ← DELETE this line

// After:
expect(schema.inputSchema).toBeDefined();
```

**Lines ~115-116:**
```typescript
// Before:
expect(schema.inputSchema.type).toBe("object");
expect(schema.inputSchema.properties).toBeDefined();

expect(schema.outputSchema.type).toBe("object");      // ← DELETE
expect(schema.outputSchema.properties).toBeDefined(); // ← DELETE

// After:
expect(schema.inputSchema.type).toBe("object");
expect(schema.inputSchema.properties).toBeDefined();
```

### Option B: Apply Patch

```bash
# Download and apply the patch
curl -O https://raw.githubusercontent.com/yourusername/perplexity-mcp-server/main/outputschema-fix.patch
git apply outputschema-fix.patch
```

### Option C: Use Script

```bash
# Create a quick fix script
cat > fix-outputschema.sh << 'EOF'
#!/bin/bash

# Backup files
cp src/schema/toolSchemas.ts src/schema/toolSchemas.ts.backup
cp src/__tests__/unit/schemas.test.ts src/__tests__/unit/schemas.test.ts.backup

# Remove outputSchema from toolSchemas.ts
sed -i '/outputSchema: {/,/},$/d' src/schema/toolSchemas.ts

# Remove outputSchema tests
sed -i '/expect(schema.outputSchema)/d' src/__tests__/unit/schemas.test.ts

echo "Fix applied! Now run: bun run build"
EOF

chmod +x fix-outputschema.sh
./fix-outputschema.sh
```

### Final Steps (All Options)

```bash
# 1. Rebuild
bun run build  # or: npm run build

# 2. Verify no errors
# Expected output: "$ tsc" (no errors)

# 3. Restart Cursor/VSCode
# Close and reopen Cursor/VSCode to reload MCP server
```

---

## Verification

### Test Each Tool

#### 1. Search ✅
```typescript
mcp_perplexity_server_search({ 
  query: "What is the capital of France?",
  detail_level: "brief"
})

// Expected: "The capital of France is Paris..."
```

#### 2. Chat ✅
```typescript
mcp_perplexity_server_chat_perplexity({
  message: "What are AI trends in 2025?"
})

// Expected: { chat_id: "...", response: "..." }
```

#### 3. Documentation ✅
```typescript
mcp_perplexity_server_get_documentation({
  query: "React useEffect hook",
  context: "focus on cleanup"
})

// Expected: "The React useEffect hook..."
```

#### 4. Check Deprecated ✅
```typescript
mcp_perplexity_server_check_deprecated_code({
  code: "componentWillMount()",
  technology: "React"
})

// Expected: "componentWillMount is deprecated..."
```

#### 5. Find APIs ✅
```typescript
mcp_perplexity_server_find_apis({
  requirement: "weather data",
  context: "prefer free tier"
})

// Expected: "AccuWeather provides..."
```

#### 6. Extract URL ✅
```typescript
mcp_perplexity_server_extract_url_content({
  url: "https://example.com/article"
})

// Expected: { url: "...", title: "...", textContent: "..." }
```

### Success Criteria

- ✅ All 6 tools return results (not errors)
- ✅ Build completes without errors
- ✅ Tests pass
- ✅ No MCP validation errors

---

## Understanding MCP

### Key Concepts

#### 1. Tool Schemas Define Contract

The schema tells MCP what to expect:

```typescript
{
  name: "toolName",
  inputSchema: { /* what the tool accepts */ },
  outputSchema: { /* what the tool returns */ }  // Optional!
}
```

#### 2. OutputSchema is Optional

- **With outputSchema:** Tool returns structured data
- **Without outputSchema:** Tool returns text content (default)

#### 3. Text Content Format

When returning text, use MCP's content format:

```typescript
return {
  content: [
    {
      type: "text",
      text: "your result here"
    }
  ]
};
```

#### 4. Structured Data Format

When returning structured data, match the outputSchema exactly:

```typescript
// Schema:
outputSchema: {
  type: "object",
  properties: {
    temp: { type: "number" },
    condition: { type: "string" }
  }
}

// Return must match:
return {
  temp: 72,
  condition: "sunny"
};
```

### Best Practices

✅ **DO:**
- Use outputSchema only for actual structured data
- Document response format in tool description
- Test tools after schema changes
- Keep schemas simple and clear

❌ **DON'T:**
- Use outputSchema for documentation
- Mix text and structured data
- Suppress linter errors without understanding
- Forget to rebuild after schema changes

---

## Resources

### Documentation Files

- **[Quick Fix Guide](./QUICK_FIX_GUIDE.md)** - 5-minute fix instructions
- **[Fix Summary](./FIX_SUMMARY.md)** - Executive summary of the fix
- **[Troubleshooting Guide](./TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md)** - Detailed troubleshooting
- **[Visual Diagram](./FIX_EXPLANATION_DIAGRAM.md)** - Flow charts and diagrams
- **[GitHub Issue Template](./GITHUB_ISSUE_TEMPLATE.md)** - For reporting issues

### Patch File

- **[outputschema-fix.patch](../git-patch/outputschema-fix.patch)** - Git patch to apply fix

### External Links

- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)

---

## FAQ

### Q: Why did this error suddenly appear?

A: The tool schemas were likely created with `outputSchema` for documentation purposes, but MCP interprets it as a validation requirement.

### Q: Will this break anything?

A: No! Removing `outputSchema` just tells MCP to accept text content (which is what the tools already return).

### Q: Do I need to change the tool implementations?

A: No! The tools are working correctly. Only the schemas need to be fixed.

### Q: What if I have custom tools?

A: Check if they return structured data or text:
- **Structured data:** Keep `outputSchema` and ensure it matches
- **Text content:** Remove `outputSchema`

### Q: Can I use outputSchema in the future?

A: Yes, but only when your tool **actually returns structured data** matching that exact schema.

### Q: What if the fix doesn't work?

A: Ensure you:
1. Removed ALL 6 outputSchema blocks
2. Updated the test file
3. Rebuilt successfully (`bun run build`)
4. Restarted Cursor/VSCode completely

---

## Support

If you need help:

1. **Check the documentation** - Start with [Quick Fix Guide](./QUICK_FIX_GUIDE.md)
2. **Review the diagram** - See [Visual Explanation](./FIX_EXPLANATION_DIAGRAM.md)
3. **Search issues** - Check if others had the same problem
4. **Create an issue** - Use [GitHub Issue Template](./GITHUB_ISSUE_TEMPLATE.md)

---

## Success! 🎉

After applying this fix:

- ✅ All 6 tools working
- ✅ 100% success rate
- ✅ No more validation errors
- ✅ Ready for development

**Happy coding!**

---

*Last Updated: September 30, 2025*  
*Status: ✅ Verified Working*  
*Fix Time: ~5 minutes*
