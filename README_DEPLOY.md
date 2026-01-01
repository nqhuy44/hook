# Deployment Guide

This guide explains how to build the Godot Frontend and deploy it alongside the Go Backend using Nginx.

## 1. Prerequisites
- Godot 4.x (with Web Export Templates installed)
- Go 1.22+
- Docker (Optional, recommended for Nginx) or local Nginx

## 2. Exporting Frontend (Godot)
1. Open `frontend/project.godot` in Godot Engine.
2. Go to **Project > Export**.
3. You should see a "Web" preset (created via `export_presets.cfg`).
4. Click **Export Project**.
5. Save files to the `static/` folder in the project root.
   - Ensure the main HTML file is named `index.html`.
   - You should have `index.html`, `index.js`, `index.pck`, and `index.wasm` (names may vary slightly by export config).

## 3. Building Backend (Go)
1. Navigate to the root folder.
2. Build the server binary:
   ```bash
   go build -o server_bin ./server
   # OR
   go build -o hook-server main.go
   ```
3. Run the server:
   ```bash
   ./hook-server
   ```
   The backend runs on port `:8080`.

## 4. Running with Nginx
We use Nginx to serve the static frontend files and proxy WebSocket connections (`/ws`) to the backend.

### Option A: Local Nginx
1. Copy `nginx.conf` to your Nginx configuration directory (or include it).
2. Point the `root` directive in `nginx.conf` to your absolute path of `static/`.
   ```nginx
   server {
       # ...
       location / {
           root /absolute/path/to/hook/static; 
           # ...
       }
   }
   ```
3. Start Nginx. open `http://localhost`.

### Option B: Docker
1. Create a `Dockerfile` for Nginx or use `docker-compose`.
2. Mount `./static` to `/usr/share/nginx/html`.
3. Mount `./nginx.conf` to `/etc/nginx/nginx.conf`.
4. Run the container.

## 5. Cleaning Up
Run the following to clean built binaries and temp files:
```bash
rm -f server_bin hook-game
rm -rf tmp/
```
