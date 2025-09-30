# GitHub Issue Template: MCP Output Schema Error

Copy this template when creating an issue about the outputSchema error:

---

## Issue: MCP Tools Failing with "Tool has an output schema but did not return structured content"

### Description

All Perplexity MCP server tools are returning the following error:

```
MCP error -32600: Tool [tool_name] has an output schema but did not return structured content
```

### Affected Tools

- [ ] search
- [ ] chat_perplexity
- [ ] get_documentation
- [ ] find_apis
- [ ] check_deprecated_code
- [ ] extract_url_content

### Environment

- **Operating System:** [e.g., Windows 10, macOS 14, Ubuntu 22.04]
- **IDE:** [e.g., Cursor, VSCode]
- **Node/Bun Version:** [e.g., Node v20.0.0, Bun v1.0.0]
- **TypeScript Version:** [e.g., 5.3.3]
- **MCP SDK Version:** [e.g., @modelcontextprotocol/sdk v0.5.0]
- **Repository:** [e.g., perplexity-mcp-zerver]

### Steps to Reproduce

1. Install the Perplexity MCP server
2. Configure MCP in Cursor/IDE settings
3. Attempt to use any tool:
   ```typescript
   mcp_perplexity_server_search({ query: "test" })
   ```
4. Observe error message

### Expected Behavior

Tool should return search results from Perplexity AI.

### Actual Behavior

Tool returns error:
```
MCP error -32600: Tool search has an output schema but did not return structured content
```

### Root Cause

The tool schemas include `outputSchema` definitions, but the tools return text content in MCP format `{ content: [{ type: "text", text: "..." }] }` instead of structured data. The MCP protocol interprets `outputSchema` as a requirement for structured data, causing a validation mismatch.

### Solution

Remove all `outputSchema` definitions from the tool schemas. See [TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md](./TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md) for detailed fix instructions.

### Quick Fix Steps

1. Edit `src/schema/toolSchemas.ts` - Remove all `outputSchema` blocks (6 occurrences)
2. Edit `src/__tests__/unit/schemas.test.ts` - Remove outputSchema test assertions (3 lines)
3. Run `bun run build` (or `npm run build`)
4. Restart Cursor/VSCode to reload the MCP server

### Verification

After applying the fix, test a tool:
```typescript
mcp_perplexity_server_search({ query: "What is MCP?" })
```

Should return results ✅ instead of error ❌

### Additional Context

- This affects all tools because they all return text content, not structured data
- The `outputSchema` was originally added for documentation purposes but MCP treats it as a validation requirement
- The fix requires only deletions, no new code needed

### Related Documentation

- [Quick Fix Guide](./QUICK_FIX_GUIDE.md)
- [Detailed Troubleshooting](./TROUBLESHOOTING_MCP_OUTPUT_SCHEMA.md)
- [Visual Explanation](./FIX_EXPLANATION_DIAGRAM.md)

### Labels

`bug` `mcp` `tools` `outputSchema` `validation` `documentation`

---

**Note:** If you've applied this fix and are still experiencing issues, please provide:
1. Complete error logs
2. Your MCP configuration file
3. Output of `bun run build` or `npm run build`
4. Confirmation that you restarted Cursor/VSCode
