# Fixing MCP "Tool has an output schema but did not return structured content" Error

## Problem Description

When using the Perplexity MCP server tools, you may encounter this error:

```
MCP error -32600: Tool [tool_name] has an output schema but did not return structured content
```

This error occurs for ALL tools (search, chat_perplexity, get_documentation, find_apis, check_deprecated_code, extract_url_content) and prevents them from working.

## Root Cause Analysis

### The Issue

The MCP (Model Context Protocol) has specific requirements for how tools return data:

1. **When `outputSchema` is defined in a tool's schema**, the MCP protocol interprets this as a requirement that the tool MUST return structured data matching that exact schema.

2. **When `outputSchema` is NOT defined**, the tool should return text content wrapped in a standard MCP response format: `{ content: [{ type: "text", text: "..." }] }`

### What Was Wrong

Our tool schemas included `outputSchema` definitions like this:

```typescript
{
  name: "search",
  inputSchema: { /* ... */ },
  outputSchema: {  // ❌ This was the problem!
    type: "object",
    properties: {
      response: {
        type: "string",
        description: "The search result text"
      }
    }
  }
}
```

However, our tool handler was returning:

```typescript
return { content: [{ type: "text", text: result }] };
```

The MCP protocol saw the `outputSchema` and expected the tool to return:

```typescript
return { response: "actual search result text" };
```

This mismatch caused the error.

### Why the OutputSchema Was There

The `outputSchema` was originally added for **documentation purposes** to describe what the text response would contain (e.g., "the response will be a JSON string with these fields"). However, the MCP protocol interprets `outputSchema` as a **requirement**, not documentation.

## The Fix

### Step 1: Remove All OutputSchema Definitions

We need to remove the `outputSchema` field from ALL tool schemas in `src/schema/toolSchemas.ts`.

**Before:**
```typescript
{
  name: "search",
  description: "Performs a web search...",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "..." },
      detail_level: { type: "string", enum: ["brief", "normal", "detailed"] }
    },
    required: ["query"]
  },
  outputSchema: {  // ❌ REMOVE THIS
    type: "object",
    properties: {
      response: { type: "string", description: "..." }
    }
  }
}
```

**After:**
```typescript
{
  name: "search",
  description: "Performs a web search...",
  inputSchema: {
    type: "object",
    properties: {
      query: { type: "string", description: "..." },
      detail_level: { type: "string", enum: ["brief", "normal", "detailed"] }
    },
    required: ["query"]
  }
  // ✅ No outputSchema - tools return text content by default
}
```

### Step 2: Apply to All Tools

Remove `outputSchema` from these tool definitions:

1. ✅ `chat_perplexity`
2. ✅ `extract_url_content`
3. ✅ `get_documentation`
4. ✅ `find_apis`
5. ✅ `check_deprecated_code`
6. ✅ `search`

### Step 3: Update Tests

Update the test file `src/__tests__/unit/schemas.test.ts` to remove outputSchema assertions:

**Before:**
```typescript
it("should have required schema properties", () => {
  TOOL_SCHEMAS.forEach(schema => {
    expect(schema.inputSchema).toBeDefined();
    expect(schema.outputSchema).toBeDefined();  // ❌ REMOVE THIS
  });
});

it("should have proper output schema definitions", () => {
  TOOL_SCHEMAS.forEach(schema => {
    expect(schema.outputSchema.type).toBe("object");  // ❌ REMOVE THIS
    expect(schema.outputSchema.properties).toBeDefined();  // ❌ REMOVE THIS
  });
});
```

**After:**
```typescript
it("should have required schema properties", () => {
  TOOL_SCHEMAS.forEach(schema => {
    expect(schema.inputSchema).toBeDefined();
    // ✅ No outputSchema check
  });
});

it("should have proper input schema definitions", () => {
  TOOL_SCHEMAS.forEach(schema => {
    expect(schema.inputSchema.type).toBe("object");
    expect(schema.inputSchema.properties).toBeDefined();
    // ✅ Only check input schema
  });
});
```

### Step 4: Rebuild and Restart

```bash
# Rebuild the TypeScript project
cd perplexity-mcp-zerver
bun run build  # or: npm run build

# Restart Cursor/VSCode to reload the MCP server
# The MCP server runs as a background process and needs to be restarted
```

## Detailed Implementation Steps

### For TypeScript/Bun Version (perplexity-mcp-zerver)

1. **Backup the schema file:**
   ```bash
   cp src/schema/toolSchemas.ts src/schema/toolSchemas.ts.backup
   ```

2. **Edit `src/schema/toolSchemas.ts`:**

   Remove all occurrences of `outputSchema` blocks. Here are the exact changes:

   **chat_perplexity tool** - Remove lines ~38-52:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     description: "...",
     properties: {
       chat_id: { type: "string", description: "..." },
       response: { type: "string", description: "..." }
     }
   },
   ```

   **extract_url_content tool** - Remove lines ~109-159:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     description: "...",
     properties: {
       status: { /* ... */ },
       message: { /* ... */ },
       rootUrl: { /* ... */ },
       explorationDepth: { /* ... */ },
       pagesExplored: { /* ... */ },
       content: { /* ... */ }
     }
   },
   ```

   **get_documentation tool** - Remove lines ~204-212:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     properties: {
       response: { type: "string", description: "..." }
     }
   },
   ```

   **find_apis tool** - Remove lines ~252-260:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     properties: {
       response: { type: "string", description: "..." }
     }
   },
   ```

   **check_deprecated_code tool** - Remove lines ~303-311:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     properties: {
       response: { type: "string", description: "..." }
     }
   },
   ```

   **search tool** - Remove lines ~363-371:
   ```typescript
   // DELETE THIS BLOCK:
   outputSchema: {
     type: "object",
     properties: {
       response: { type: "string", description: "..." }
     }
   },
   ```

3. **Edit `src/__tests__/unit/schemas.test.ts`:**

   **Line ~30** - Change:
   ```typescript
   // Before:
   expect(schema.inputSchema).toBeDefined();
   expect(schema.outputSchema).toBeDefined();
   
   // After:
   expect(schema.inputSchema).toBeDefined();
   ```

   **Lines ~115-116** - Remove:
   ```typescript
   // DELETE THESE LINES:
   expect(schema.outputSchema.type).toBe("object");
   expect(schema.outputSchema.properties).toBeDefined();
   ```

4. **Rebuild:**
   ```bash
   bun run build
   ```

   Expected output:
   ```
   $ tsc
   ```
   (No errors)

5. **Restart Cursor/VSCode** to reload the MCP server

### For Python Version (perplexity-mcp-simple)

If you're using the Python version, you also need to fix the return format:

1. **Edit `perplexity_mcp/server/mcp_server.py`:**

   **Line ~79** - Update return type:
   ```python
   # Before:
   async def call_tool(name: str, arguments: Dict[str, Any]) -> list[TextContent]:
   
   # After:
   async def call_tool(name: str, arguments: Dict[str, Any]) -> Dict[str, Any]:
   ```

   **Line ~105 and ~129** - Update return statements:
   ```python
   # Before:
   return [TextContent(type="text", text=result)]
   
   # After:
   return {"content": [{"type": "text", "text": result}]}
   ```

   **Line ~133** - Update error return:
   ```python
   # Before:
   return [TextContent(type="text", text=error_msg)]
   
   # After:
   return {"content": [{"type": "text", "text": error_msg}]}
   ```

2. **Update `perplexity_mcp/tools/schemas.py`:**

   Remove all `outputSchema` fields from `TOOL_SCHEMAS` list (similar to TypeScript version)

3. **Restart the MCP server**

## Verification

After implementing the fix, test each tool:

### 1. Test Search
```typescript
// Should return detailed search results with sources
await mcp_perplexity_server_search({
  query: "What is the capital of France?",
  detail_level: "brief"
});
```

### 2. Test Chat
```typescript
// Should return response with chat_id for conversation tracking
await mcp_perplexity_server_chat_perplexity({
  message: "What are the latest AI trends?"
});
```

### 3. Test Documentation
```typescript
// Should return detailed documentation with examples
await mcp_perplexity_server_get_documentation({
  query: "React useEffect hook",
  context: "focus on cleanup and dependencies"
});
```

### 4. Test Deprecated Code Checker
```typescript
// Should identify deprecated patterns and suggest alternatives
await mcp_perplexity_server_check_deprecated_code({
  code: "componentWillMount()",
  technology: "React"
});
```

### 5. Test API Finder
```typescript
// Should find relevant APIs with details
await mcp_perplexity_server_find_apis({
  requirement: "weather data",
  context: "prefer free tier"
});
```

### 6. Test URL Extractor
```typescript
// Should extract clean article content
await mcp_perplexity_server_extract_url_content({
  url: "https://react.dev/reference/react/useEffect",
  depth: 1
});
```

## Understanding MCP Tool Return Formats

### When to Use OutputSchema

Use `outputSchema` ONLY when your tool returns **actual structured data** (not just text containing JSON):

```typescript
// ✅ Correct - Tool returns structured data
async function structuredTool(args) {
  return {
    temperature: 72,
    conditions: "sunny",
    timestamp: "2025-09-30T12:00:00Z"
  };
}

// Tool schema with outputSchema
{
  name: "structuredTool",
  inputSchema: { /* ... */ },
  outputSchema: {  // ✅ Correct - matches actual return
    type: "object",
    properties: {
      temperature: { type: "number" },
      conditions: { type: "string" },
      timestamp: { type: "string" }
    }
  }
}
```

### When NOT to Use OutputSchema

Don't use `outputSchema` when your tool returns **text content**:

```typescript
// ✅ Correct - Tool returns text
async function textTool(args) {
  const result = await searchEngine.search(args.query);
  return result; // Returns string
}

// Tool handler wraps it in MCP format
return { content: [{ type: "text", text: result }] };

// Tool schema WITHOUT outputSchema
{
  name: "textTool",
  inputSchema: { /* ... */ },
  // ✅ No outputSchema - returns text content
}
```

## Common Mistakes to Avoid

### ❌ Mistake 1: Using OutputSchema for Documentation
```typescript
// DON'T DO THIS:
outputSchema: {
  type: "object",
  description: "The response will be a JSON string with these fields...",
  // ...
}
```

Instead, describe the response format in the tool's `description` field.

### ❌ Mistake 2: Mismatched Return Format
```typescript
// Tool schema says it returns structured data:
outputSchema: {
  type: "object",
  properties: { result: { type: "string" } }
}

// But tool handler returns text:
return { content: [{ type: "text", text: "..." }] }; // ❌ Mismatch!
```

### ❌ Mistake 3: Suppressing Linter Without Understanding
```typescript
// DON'T DO THIS:
// eslint-disable-next-line @typescript-eslint/no-unused-vars
const outputSchema = { /* ... */ };
```

If the linter complains, it's probably because you don't need `outputSchema`.

## Additional Resources

- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [Perplexity MCP Server Repository](https://github.com/yourusername/perplexity-mcp-server)
- [MCP SDK TypeScript](https://github.com/modelcontextprotocol/typescript-sdk)
- [MCP SDK Python](https://github.com/modelcontextprotocol/python-sdk)

## Summary

The fix is simple but critical:

1. **Remove all `outputSchema` definitions** from tool schemas
2. **Update tests** to not check for outputSchema
3. **Rebuild** the project
4. **Restart** the MCP server (restart Cursor/VSCode)

This allows tools to return text content in the standard MCP format without triggering validation errors.

## Support

If you encounter issues after applying this fix:

1. Check that you removed ALL outputSchema definitions (use grep to search)
2. Verify the build completed without errors
3. Ensure you restarted Cursor/VSCode completely to reload the MCP server
4. Check the MCP server logs for any additional errors
5. Test each tool individually to isolate the problem

Created: 2025-09-30
Last Updated: 2025-09-30
Status: ✅ Verified Working

