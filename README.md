# [Perplexity-MCP-**Z**erver](https://github.com/wysh3/perplexity-mcp-zerver) Fix for Cursor/VSCode

No API key requred!

### 🤖 Method 1: Easiest Fix
---
1. Give the docs to your Cursor AI coding agent
2. Ask: *"Please please please implement the MCP OutputSchema fix described in these docs!"*


### ⚡ Method 2: Automated Script
---
**Windows PowerShell:**
```powershell
cd automated-scripts
.\quick-fix.ps1
```

**Mac/Linux Bash:**
```bash
cd automated-scripts
chmod +x quick-fix.sh
./quick-fix.sh
```

### 🔧 Method 3: Git Patch
---
```bash
cd /path/to/your/perplexity-mcp-zerver
git apply /path/to/this/git-patch/outputschema-fix.patch
bun run build
```

### 📝 Method 4: Manual Fix
---
1. Read [`docs/QUICK_FIX_GUIDE.md`](docs/QUICK_FIX_GUIDE.md)
2. Follow the step-by-step instructions
3. Rebuild and restart the MCP **Z**erver

**See [`QUICKSTART.md`](QUICKSTART.md) for detailed instructions.**

---

---
Original repo: [Perplexity-MCP-**Z**erver](https://github.com/wysh3/perplexity-mcp-zerver) - 
[https://github.com/wysh3/perplexity-mcp-zerver](https://github.com/wysh3/perplexity-mcp-zerver)
