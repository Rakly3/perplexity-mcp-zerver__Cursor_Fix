# Visual Explanation: MCP OutputSchema Fix

## The Error Flow (Before Fix)

```
┌─────────────────────────────────────────────────────────────────┐
│ User calls tool                                                 │
│ mcp_perplexity_server_search({ query: "test" })                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ MCP Protocol checks tool schema                                 │
│                                                                 │
│ Tool Schema:                                                    │
│ {                                                               │
│   name: "search",                                               │
│   inputSchema: { ... },                                         │
│   outputSchema: {           ◄─── MCP sees this!                 │
│     type: "object",                                             │
│     properties: { response: { type: "string" } }                │
│   }                                                             │
│ }                                                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ MCP expects tool to return:
                            │ { response: "result text" }
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tool Handler executes                                           │
│                                                                 │
│ async function search(args) {                                   │
│   const result = await performSearch(args.query);               │
│   return result; // Returns plain string                        │
│ }                                                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tool Handler Setup wraps result                                 │
│                                                                 │
│ return {                                                        │
│   content: [                                                    │
│     { type: "text", text: result }                              │
│   ]                                                             │
│ };                                                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ Actual return format:
                            │ { content: [{ type: "text", text: "..." }] }
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ MCP Protocol validation                                         │
│                                                                 │
│ Expected: { response: "..." }                                   │
│ Got:      { content: [...] }                                    │
│                                                                 │
│ ❌ MISMATCH! Throw error:                                      |
│ "Tool has an output schema but did not                          │
│  return structured content"                                     │
└─────────────────────────────────────────────────────────────────┘
```

## The Fixed Flow (After Fix)

```
┌─────────────────────────────────────────────────────────────────┐
│ User calls tool                                                 │
│ mcp_perplexity_server_search({ query: "test" })                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ MCP Protocol checks tool schema                                 │
│                                                                 │
│ Tool Schema:                                                    │
│ {                                                               │
│   name: "search",                                               |
│   inputSchema: { ... }                                          │
│   // No outputSchema!     ◄─── MCP sees no outputSchema         │
│ }                                                               │
│                                                                 │
│ MCP default: expects text content format                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ MCP expects:
                            │ { content: [{ type: "text", text: "..." }] }
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tool Handler executes                                           │
│                                                                 │
│ async function search(args) {                                   │
│   const result = await performSearch(args.query);               │
│   return result; // Returns plain string                        │
│ }                                                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tool Handler Setup wraps result                                 │
│                                                                 │
│ return {                                                        │
│   content: [                                                    │
│     { type: "text", text: result }                              │
│   ]                                                             │
│ };                                                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ Actual return format:
                            │ { content: [{ type: "text", text: "..." }] }
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ MCP Protocol validation                                         │
│                                                                 │
│ Expected: { content: [{ type: "text", text: "..." }] }          │
│ Got:      { content: [{ type: "text", text: "..." }] }          │
│                                                                 │
│ ✅ MATCH! Return result to user                                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ User receives search results! 🎉                               │
│                                                                 │
│ "The capital of France is Paris..."                             │
└─────────────────────────────────────────────────────────────────┘
```

## Key Concept: Two Types of Tool Returns

### Type 1: Structured Data Tools (Need OutputSchema)

```typescript
// Tool returns actual structured object
async function getWeather(args) {
  return {
    temperature: 72,
    conditions: "sunny",
    humidity: 45
  };
}

// Schema MUST have outputSchema
{
  name: "getWeather",
  outputSchema: {
    type: "object",
    properties: {
      temperature: { type: "number" },
      conditions: { type: "string" },
      humidity: { type: "number" }
    }
  }
}

// MCP expects: { temperature: 72, conditions: "sunny", ... }
// Tool returns: { temperature: 72, conditions: "sunny", ... }
// ✅ Match!
```

### Type 2: Text Content Tools (No OutputSchema)

```typescript
// Tool returns text string
async function search(args) {
  const result = await performSearch(args.query);
  return result; // Returns: "Paris is the capital..."
}

// Handler wraps it
return {
  content: [{ type: "text", text: result }]
};

// Schema should NOT have outputSchema
{
  name: "search",
  inputSchema: { ... }
  // No outputSchema!
}

// MCP expects: { content: [{ type: "text", text: "..." }] }
// Tool returns: { content: [{ type: "text", text: "..." }] }
// ✅ Match!
```

## The Root Cause

```
Original Intent              MCP Protocol Interpretation
─────────────────            ───────────────────────────

outputSchema: {              "This tool MUST return
  description:                an object with a 'response'
    "The response            field, not text content"
     contains..."            
  properties: {              Expected return:
    response: string         { response: "text" }
  }                          
}                            NOT:
                             { content: [...] }

Purpose: Documentation       Purpose: Validation Rule
```

## Why Removing OutputSchema Works

```
┌──────────────────────────────────────────────────────────┐
│ MCP Protocol Default Behavior                            │
├──────────────────────────────────────────────────────────┤
│                                                          │
│ IF tool schema has outputSchema:                         │
│   ✓ Validate return against outputSchema                │
│   ✓ Expect structured data matching schema              │
│   ✗ Reject text content format                          │
│                                                          │
│ IF tool schema has NO outputSchema:                      │
│   ✓ Accept text content format                          │
│   ✓ Expect: { content: [{ type: "text", ... }] }        │
│   ✓ No additional validation                            │
│                                                          │
└──────────────────────────────────────────────────────────┘

Our tools return TEXT, not STRUCTURED DATA
Therefore: Don't use outputSchema! ✅
```

## Before vs After Comparison

### Before (Broken)

```typescript
// src/schema/toolSchemas.ts
export const TOOL_SCHEMAS = [
  {
    name: "search",
    inputSchema: { /* ... */ },
    outputSchema: {                    // ❌ Problem!
      type: "object",
      properties: {
        response: { type: "string" }
      }
    }
  },
  // ... 5 more tools with same issue
];

// Result: All 6 tools fail with error ❌
```

### After (Fixed)

```typescript
// src/schema/toolSchemas.ts
export const TOOL_SCHEMAS = [
  {
    name: "search",
    inputSchema: { /* ... */ }
    // ✅ No outputSchema!
  },
  // ... 5 more tools fixed
];

// Result: All 6 tools work perfectly! ✅
```

## File Change Summary

```
src/schema/toolSchemas.ts
├─ Line ~38-52:   DELETE outputSchema (chat_perplexity)
├─ Line ~109-159: DELETE outputSchema (extract_url_content)
├─ Line ~204-212: DELETE outputSchema (get_documentation)
├─ Line ~252-260: DELETE outputSchema (find_apis)
├─ Line ~303-311: DELETE outputSchema (check_deprecated_code)
└─ Line ~363-371: DELETE outputSchema (search)

src/__tests__/unit/schemas.test.ts
├─ Line ~30:      DELETE expect(outputSchema).toBeDefined()
└─ Line ~115-116: DELETE outputSchema validation tests

Total Changes: 9 deletions across 2 files
Build: ✅ Success
Tests: ✅ Pass
Tools: ✅ All 6 working
```

## Testing the Fix

```typescript
// Before Fix
mcp_perplexity_server_search({ query: "test" })
❌ Error: "Tool has an output schema but did not return structured content"

// After Fix
mcp_perplexity_server_search({ query: "test" })
✅ Returns: "Detailed search results with sources and URLs..."

// All 6 tools now work:
✅ search
✅ chat_perplexity
✅ get_documentation
✅ find_apis
✅ check_deprecated_code
✅ extract_url_content
```

## Lesson Learned

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│  Only use outputSchema when your tool actually         │
│  returns structured data as the PRIMARY response.      │
│                                                        │
│  If your tool returns text (even if that text          │
│  contains JSON), don't use outputSchema!               │
│                                                        │
│  The MCP protocol takes outputSchema literally         │
│  as a validation contract, not documentation.          │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

Created: 2025-09-30  
Fixed by: Removing all outputSchema definitions  
Status: ✅ Verified working across all 6 tools
