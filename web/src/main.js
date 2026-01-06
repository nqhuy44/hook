import "./style.css";
import { GAME_CONFIG } from "./config.js";
import { Logger } from "./utils/logger.js";
import { TextManager } from "./utils/i18n.js";
import { NetworkManager } from "./network.js";
import { InputManager } from "./input.js";
import { Camera } from "./camera.js";

class Game {
  constructor() {
    this.canvas = document.getElementById("gameCanvas");
    this.ctx = this.canvas.getContext("2d", { alpha: false });

    // Modules
    this.textManager = new TextManager();
    this.network = new NetworkManager();
    this.camera = new Camera(this.canvas);
    this.input = new InputManager(this.canvas, this.network, this.camera);

    // Game State
    this.gameState = {
      players: {}, // Map ID -> Player
    };
    this.myPlayerID = null;

    this.init();
  }

  init() {
    document.title = this.textManager.get("GAME_TITLE");

    this.resize();
    window.addEventListener("resize", () => this.resize());

    this.setupNetwork();

    // Loop
    this.lastTime = 0;
    requestAnimationFrame((time) => this.loop(time));
  }

  setupNetwork() {
    const checkReady = setInterval(() => {
      if (this.network) {
        clearInterval(checkReady);
        this.bindNetworkEvents();
        this.network.connect();
      }
    }, 100);
  }

  bindNetworkEvents() {
    this.network.onOpen = () => Logger.info("Connected to Server");

    this.network.onMessage = (data) => {
      switch (data.type) {
        case "room_joined":
          this.myPlayerID = data.id;
          Logger.info("Joined Room as", this.myPlayerID);
          break;
        case "game_update":
          // Server sends { type: 'game_update', state: { players: [...] } }
          // We just store it for rendering
          if (data.state && data.state.Players) {
            // Convert map/array to usable state
            this.gameState.players = data.state.Players;
          }
          break;
      }
    };
  }

  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
    this.camera.centerOnMap();
  }

  loop(timestamp) {
    const dt = (timestamp - this.lastTime) / 1000;
    this.lastTime = timestamp;

    this.update(dt);
    this.draw(timestamp);

    requestAnimationFrame((time) => this.loop(time));
  }

  update(dt) {
    // Client-side prediction or interpolation could go here
  }

  draw(time) {
    // 1. Clear Void
    this.ctx.fillStyle = GAME_CONFIG.COLORS.BG_DEEP;
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // 2. Camera Transform
    this.ctx.save();
    this.camera.apply(this.ctx);

    // 3. Render World
    this.renderMap(time);
    this.renderEntities();

    // 4. Input Debug (Mouse Cursor or Aim Line)
    this.renderAiming();

    this.ctx.restore();

    // 5. HUD (Not implemented yet - Overlay)
  }

  renderMap(time) {
    const { WIDTH, HEIGHT, RIVER_WIDTH } = GAME_CONFIG.MAP;
    const { COLORS } = GAME_CONFIG;

    // Floor
    this.ctx.fillStyle = COLORS.BG_FLOOR;
    this.ctx.fillRect(0, 0, WIDTH, HEIGHT);

    // Grid (Dots/Lines)
    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.strokeStyle = COLORS.GRID_LINE;
    this.ctx.lineWidth = 1;

    // Draw grid lines every 80px (matching css bg-size)
    const gridSize = 80;
    for (let x = 0; x <= WIDTH; x += gridSize) {
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, HEIGHT);
    }
    for (let y = 0; y <= HEIGHT; y += gridSize) {
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(WIDTH, y);
    }
    this.ctx.stroke();
    this.ctx.restore();

    // River
    const riverX = WIDTH / 2 - RIVER_WIDTH / 2;

    this.ctx.fillStyle = COLORS.ACCENT_CYAN;
    this.ctx.fillRect(riverX, 0, RIVER_WIDTH, HEIGHT);

    // River Borders
    this.ctx.fillStyle = COLORS.RIVER_BORDER;
    this.ctx.fillRect(riverX, 0, 6, HEIGHT); // Left border
    this.ctx.fillRect(riverX + RIVER_WIDTH - 6, 0, 6, HEIGHT); // Right border

    // River Waves (Simple Animation)
    this.ctx.save();
    // Clip to river area
    this.ctx.beginPath();
    this.ctx.rect(riverX, 0, RIVER_WIDTH, HEIGHT);
    this.ctx.clip();

    this.ctx.fillStyle = "rgba(255, 255, 255, 0.3)";
    const waveSpeed = 0.05; // px/ms
    const waveOffset = (time * waveSpeed) % 200;

    // Draw generic wave bars moving down
    for (let i = -200; i < HEIGHT; i += 200) {
      const y = i + waveOffset;
      // Draw a rounded rect for wave
      this.drawRoundedRect(this.ctx, riverX + 20, y, RIVER_WIDTH - 40, 8, 4);
      this.ctx.fill();

      // Second offset wave
      this.drawRoundedRect(
        this.ctx,
        riverX + 40,
        y + 100,
        RIVER_WIDTH - 80,
        5,
        2
      );
      this.ctx.fill();
    }

    this.ctx.restore();
  }

  renderEntities() {
    const players = Object.values(this.gameState.players);

    for (const p of players) {
      this.drawCharacter(p);
    }
  }

  drawCharacter(p) {
    const { x, y, team, id, name } = p;
    const color =
      team === 1
        ? GAME_CONFIG.COLORS.ACCENT_GREEN
        : GAME_CONFIG.COLORS.ACCENT_RED; // 1=Radiant, 2=Dire
    // Or using Colors based on ID/Index if distinct colors needed.

    // Handle visual rotation (facing mouse) logic derived from server data or local if existing
    // For now assume default down or simple logic
    const radius = 30; // 60px diameter

    this.ctx.save();
    this.ctx.translate(x, y);

    // Body Body
    this.ctx.beginPath();
    this.ctx.arc(0, 0, radius, 0, Math.PI * 2);
    this.ctx.fillStyle = color;
    this.ctx.fill();
    this.ctx.lineWidth = 4;
    this.ctx.strokeStyle = GAME_CONFIG.COLORS.ENTITY_BORDER;
    this.ctx.stroke();

    // Hands (Simple circles)
    const handOffset = 25;
    this.ctx.beginPath();
    this.ctx.arc(handOffset, 15, 10, 0, Math.PI * 2); // Right hand
    this.ctx.fillStyle = "#1a1a1a";
    this.ctx.fill();

    this.ctx.beginPath();
    this.ctx.arc(-handOffset, 15, 10, 0, Math.PI * 2); // Left hand
    this.ctx.fillStyle = "#1a1a1a";
    this.ctx.fill();

    // Weapon (Rect) on Right Hand
    this.ctx.fillStyle = "#555";
    this.ctx.fillRect(handOffset - 2, 5, 8, -25); // Vertical stick

    this.ctx.restore();

    // Overhead UI (Name + HP)
    this.drawOverheadUI(p);
  }

  drawOverheadUI(p) {
    const { x, y, name, hp, maxHP } = p;

    this.ctx.save();
    this.ctx.translate(x, y - 50); // Move above head

    // Name Tag
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.4)";
    this.ctx.font = "bold 12px Nunito, sans-serif";
    const textMetrics = this.ctx.measureText(name || "Player");
    const textWidth = textMetrics.width;
    const padding = 6;

    // Background Pill
    this.drawRoundedRect(
      this.ctx,
      -textWidth / 2 - padding,
      -20,
      textWidth + padding * 2,
      18,
      9
    );
    this.ctx.fill();

    // Text
    this.ctx.fillStyle = "white";
    this.ctx.textAlign = "center";
    this.ctx.fillText(name || "Player", 0, -7);

    // HP Bar Container
    const barW = 50;
    const barH = 6;
    this.ctx.fillStyle = GAME_CONFIG.COLORS.HP_BAR_BG;
    this.drawRoundedRect(this.ctx, -barW / 2, 2, barW, barH, 2);
    this.ctx.fill();
    this.ctx.stroke(); // Thin border

    // HP Fill
    const pct = Math.max(0, Math.min(1, (hp || 100) / (maxHP || 100)));
    this.ctx.fillStyle =
      p.team === 1
        ? GAME_CONFIG.COLORS.ACCENT_GREEN
        : GAME_CONFIG.COLORS.ACCENT_RED; // Dynamic Color? Or Green for all/self?
    // Prompt says field.html logic: Enemy Red, Self/Ally Green.
    // Need to check relationship with myPlayerID once implemented.
    this.drawRoundedRect(this.ctx, -barW / 2, 2, barW * pct, barH, 2);
    this.ctx.fill();

    this.ctx.restore();
  }

  renderAiming() {
    if (!this.myPlayerID || !this.gameState.players[this.myPlayerID]) return;

    const ME = this.gameState.players[this.myPlayerID];
    const mouse = this.input.getMouseWorld();

    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.moveTo(ME.x, ME.y);
    this.ctx.lineTo(mouse.x, mouse.y);
    this.ctx.strokeStyle = "rgba(255, 255, 255, 0.2)";
    this.ctx.setLineDash([5, 5]);
    this.ctx.stroke();
    this.ctx.restore();
  }

  // Helper
  drawRoundedRect(ctx, x, y, w, h, r) {
    if (w < 2 * r) r = w / 2;
    if (h < 2 * r) r = h / 2;
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }
}

window.onload = () => {
  new Game();
};
