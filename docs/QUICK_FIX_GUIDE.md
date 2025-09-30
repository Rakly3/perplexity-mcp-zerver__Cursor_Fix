# Quick Fix Guide: MCP Output Schema Error

## The Problem
```
MCP error -32600: Tool has an output schema but did not return structured content
```

## The Solution (5 Minutes)

### Step 1: Remove OutputSchema from Tool Schemas

Edit `src/schema/toolSchemas.ts` and **delete all `outputSchema` blocks**:

```typescript
// ❌ DELETE blocks that look like this:
outputSchema: {
  type: "object",
  properties: {
    response: { type: "string", description: "..." }
  }
},
```

Search for `outputSchema:` and remove **6 occurrences** (one for each tool).

### Step 2: Fix the Tests

Edit `src/__tests__/unit/schemas.test.ts`:

**Line ~30:**
```typescript
// DELETE this line:
expect(schema.outputSchema).toBeDefined();
```

**Lines ~115-116:**
```typescript
// DELETE these lines:
expect(schema.outputSchema.type).toBe("object");
expect(schema.outputSchema.properties).toBeDefined();
```

### Step 3: Rebuild

```bash
bun run build
```

### Step 4: Restart

**Restart Cursor/VSCode completely** to reload the MCP server.

## Why This Works

- MCP tools return text by default: `{ content: [{ type: "text", text: "..." }] }`
- `outputSchema` tells MCP to expect structured data instead
- Our tools return text, not structured data
- Removing `outputSchema` fixes the mismatch

## Verify It Works

Test any tool:
```typescript
mcp_perplexity_server_search({ query: "test" })
```

Should return results instead of an error! ✅

## Files Changed

- `src/schema/toolSchemas.ts` - Remove all `outputSchema` blocks (6 deletions)
- `src/__tests__/unit/schemas.test.ts` - Remove outputSchema assertions (3 deletions)

## Total Changes

- **9 deletions** (no additions needed!)
- **2 files** modified
- **5 minutes** to implement
- **100% fix rate** for all 6 tools

---

For detailed explanation, see [TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md](./TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md)

