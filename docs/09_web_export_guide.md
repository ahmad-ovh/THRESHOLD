# Step-by-Step Guide: Exporting THRESHOLD Godot Client to Web (HTML5/WebAssembly)

This guide provides complete, step-by-step instructions for exporting the **THRESHOLD** Godot 4 3D client to a WebAssembly/HTML5 web application, testing it locally, and deploying it to production.

---

## 📋 Prerequisites

Before exporting, ensure you have:
1. **Godot Engine 4.x** installed (matching the version used by the project).
2. **Godot Export Templates** for your Godot version:
   - In Godot Editor, go to **Editor** → **Manage Export Templates...**
   - Click **Download and Install** (or load from file if offline).
3. **Python 3.10+** (for running the THRESHOLD backend & local test web server).

---

## 🛠️ Step 1: Verify Web Export Preset in Godot

The project already includes a pre-configured Web export preset in `client/export_presets.cfg`.

### Via Godot Editor GUI:
1. Open the Godot Editor and load the `client/project.godot` project.
2. In the top menu, navigate to **Project** → **Export...**
3. You should see a preset named **Web** on the left panel.
4. Verify the following key settings under the **Web** preset:
   - **VRAM Texture Compression / Desktop**: `Enabled (true)`
   - **Canvas Resize Policy**: `Adaptive (2)`
   - **Focus Canvas on Start**: `Enabled (true)`

---

## 📦 Step 2: Exporting the Project

### Option A: Exporting via Godot Editor GUI
1. Open **Project** → **Export...**
2. Select the **Web** preset.
3. Click **Export Project...** at the bottom.
4. Create a target directory (e.g., `web_build/` at project root).
5. Set the output filename to `index.html`.
6. Uncheck **Export With Debug** if creating a production build (or keep it checked for testing).
7. Click **Save**. Godot will generate:
   - `index.html`
   - `index.js`
   - `index.wasm`
   - `index.pck`

### Option B: Exporting via Command Line (PowerShell)
You can automate the export without opening the editor UI:

```powershell
# Create output directory
New-Item -ItemType Directory -Force -Path "web_build"

# Run Godot headless export
godot --headless --path "./client" --export-release "Web" "../web_build/index.html"
```

---

## 🌐 Step 3: Running & Testing Locally

> ⚠️ **Important**: WebAssembly games **cannot** be played by simply double-clicking `index.html` due to browser CORS and security policies. You must serve the files over HTTP/HTTPS.

### Method 1: One-Click Godot Editor Testing
1. In Godot Editor, click the **Play in Browser** icon (small globe icon in the upper-right corner of the editor UI).
2. Godot will spin up a local web server with Cross-Origin Isolation headers automatically and open your default browser.

### Method 2: Local Python HTTP Server
Run a Python HTTP server with Cross-Origin headers (`COOP`/`COEP`) enabled:

```powershell
# Save as serve_web.py or run via PowerShell inline:
python -c "
import http.server, socketserver

class DualHeaderHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

PORT = 8060
handler = DualHeaderHandler
with socketserver.TCPServer(('', PORT), handler) as httpd:
    print(f'Serving THRESHOLD Web Client at http://localhost:{PORT}')
    httpd.serve_forever()
"
```

Then open your browser to [http://localhost:8060](http://localhost:8060).

---

## 🔗 Step 4: Connecting Web Client to FastAPI Backend

1. **Start THRESHOLD Backend**:
   ```powershell
   # In project root:
   python -m uvicorn src.main:app --reload --port 8000
   ```
2. **CORS Configuration**:
   Ensure `src/main.py` has CORS enabled for the web client origin:
   ```python
   from fastapi.middleware.cors import CORSMiddleware

   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],  # Or specific domain in production
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

---

## 🚀 Step 5: Production Deployment Options

### 1. itch.io (Recommended for Games)
1. Zip all files in your `web_build/` folder (`index.html`, `index.js`, `index.wasm`, `index.pck`).
2. Upload the zip file to your itch.io project page.
3. Set project type to **HTML**.
4. In itch.io settings, check **"SharedArrayBuffer support"** (enables Cross-Origin Isolation headers).

### 2. GitHub Pages / Vercel / Netlify
1. Commit the contents of `web_build/` or configure a CI/CD build script.
2. Configure HTTP headers on your hosting provider:
   - `Cross-Origin-Opener-Policy: same-origin`
   - `Cross-Origin-Embedder-Policy: require-corp`

---

## 🔍 Troubleshooting Checklist

| Issue | Cause | Fix |
|---|---|---|
| `SharedArrayBuffer` error on startup | Missing COOP/COEP headers | Use `serve_web.py` locally or enable COOP/COEP headers on host |
| Black screen / WebAssembly fail | Missing Web export templates | Reinstall templates in Godot (`Editor -> Manage Export Templates`) |
| API fetch failed in browser | CORS blocked by backend | Add `CORSMiddleware` in FastAPI `src/main.py` |
| Textures appear corrupted/black | Unsupported VRAM compression | Ensure `vram_texture_compression/for_desktop=true` in `export_presets.cfg` |
