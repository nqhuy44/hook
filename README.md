# HooK

**HooK** is a fast-paced multiplayer arena game inspired by "Pudge Wars". Players control a hero with a grappling hook to pull enemies into their territory and instant-kill them. The game features real-time physics, skillshots, and bot AI.

![HooK Gameplay](https://via.placeholder.com/800x450?text=HooK+Gameplay+Screenshot)

## 🚀 Features

-   **Multiplayer**: Real-time WebSocket-based networking.
-   **Skillshots**: "Meat Hook" (Q) with physics-based projectiles and reflection.
-   **Combat**: 4 Skills (Hook, Rot, Leap, Dismember).
-   **AI Bots**: Smart(ish) bots that hook, defend, and seek targets.
-   **Godot Frontend**: Modern, high-performance client using Godot 4.5.1.
-   **Canvas Engine**: *Legacy web client archived.*
-   **Go Backend**: High-performance, concurrent server-authoritative logic.

---

## 🛠 Development Guide

### Prerequisites
-   **Go**: Version 1.18 or higher.
-   **Browser**: Chrome / Firefox / Safari (Modern).

### Running Locally
1.  **Clone the repo**:
    ```bash
    git clone https://github.com/your-repo/hook.git
    cd hook
    ```
2.  **Run the Server**:
    ```bash
    go run .
    ```
    You should see: `Pudge Wars Server started on :8080`.

3.  **Play**:
    -   Open the `frontend` folder in **Godot 4.5.1**.
    -   Press **Play** in the Godot Editor.
    -   Connects to `ws://localhost:8080/ws` by default.

### Code Structure
-   `main.go`: Entry point. Sets up HTTP/Static file serving.
-   `server/server.go`: WebSocket upgrades and message routing (`ServeWS`).
-   `game/`: Core Game Logic.
    -   `engine.go`: The Brain. Game Loop (`Update`), Collision, AI, Skills.
    -   `types.go`: Struct definitions (`Entity`, `Vector`, `GameState`).
-   `static/`: Frontend Assets.
    -   `index.html`: UI Layout (Menu, Lobby, HUD).
    -   `game.js`: Rendering loop, Input handling, Interpolation.
    -   `style.css`: Premium Glassmorphism UI styling.

---

## 🌍 Deployment Guide

To deploy **HooK** to a Linux production server (Ubuntu/Debian).

### 1. Build (Cross-Compile for Linux)
Since you are likely developing on Mac/Windows but deploying to Linux, you **MUST** cross-compile.

```bash
# Build for Linux (AMD64/x86_64)
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o hook-game .
```
*Note: If your server is ARM (e.g., Raspberry Pi), use `GOARCH=arm64`.*

### 2. Install
Copy the binary and assets to your server folder (e.g., `/opt/hook-game`):
```bash
mkdir -p /opt/hook-game
cp hook-game /opt/hook-game/
cp -r static /opt/hook-game/
```

### 3. Run as Service (Systemd)
Create `/etc/systemd/system/hook-game.service`:

```ini
[Unit]
Description=HooK Game Server
After=network.target

[Service]
User=root
WorkingDirectory=/opt/hook-game
ExecStart=/opt/hook-game/hook-game
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable --now hook-game
```

### 4. Nginx Reverse Proxy (WebSocket Support)
Configure Nginx to forward traffic and upgrade WebSockets.

```nginx
server {
    listen 80;
    server_name play.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}

### Troubleshooting: Nginx in Docker
If you see **Error 499, 502, or 504** in Nginx logs:
1.  **Check IP**: Verify the Docker Bridge IP on the host:
    ```bash
    ip addr show docker0
    # Look for inet address, e.g., 172.17.0.1
    ```
2.  **Firewall (Critical)**: Your host firewall (UFW) might be blocking the Docker container from accessing port 8080.
    ```bash
    # Allow port 8080
    sudo ufw allow 8080/tcp
    # OR trust the docker interface
    sudo ufw allow in on docker0
    ```
3.  **Test Connectivity**:
    Run `curl` *from inside* the Nginx container:
    ```bash
    docker exec -it <nginx_container_id> curl -v http://172.17.0.1:8080
    ```
    If it hangs, it's a firewall issue. If "Connection Refused", the game isn't running or listening on 0.0.0.0.

```
***Ensure you restart Nginx after config!***
