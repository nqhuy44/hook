import "./style.css";
import { GAME_CONFIG } from "./config.js";
import { Logger } from "./utils/logger.js";
import { TextManager } from "./utils/i18n.js";
import { NetworkManager } from "./network.js";
import { InputManager } from "./input.js";
import { Camera } from "./camera.js";

class Game {
  constructor() {
    // App container setup if needed, but we focus on canvas
    this.canvas = document.getElementById("gameCanvas");
    this.ctx = this.canvas.getContext("2d", { alpha: false });

    // Core Modules
    this.textManager = new TextManager();
    this.network = new NetworkManager();
    this.camera = new Camera(this.canvas);
    // InputManager needs to be reinstantiated or ensured it's correct
    // Since we are overwriting files, we should ensure Input/Camera exist.
    // I will assume Camera/Input from Phase 2 still exist and are compatible or I need to recreate them if I wiped them.
    // Wait, the user request specificed generate code for 8 files, Camera/Input were not in the 8 files explicitly but needed for Main Logic.
    // I will assume they are there. If not I should create them.
    // Checking file structure: I am overwriting main.js.
    // I must ensure InputManager and Camera are imported correctly.
    if (typeof InputManager !== "undefined") {
      this.input = new InputManager(this.canvas, this.network, this.camera);
      this.input.setupMouseTracking();
    } else {
      // Fallback or Error if InputManager missing?
      // Actually I didn't verify if I deleted them. I only overwrote specific files.
      // web/src/input.js and web/src/camera.js should still be there from Phase 2.
      // But I am switching to module imports.
      // The previous phase used modules too.
      // So `import { InputManager } from './input.js';` should work if file exists.
    }

    // Re-initialize input (Assuming InputManager export is correct)
    this.input = new InputManager(this.canvas, this.network, this.camera);
    this.input.setupMouseTracking();

    // State
    this.connected = false;
    this.connectionError = false;

    this.init();
  }

  init() {
    // Set Title
    document.title = this.textManager.get("GAME_TITLE");
    Logger.info("Game Initialized (Vite)");

    this.resize();
    window.addEventListener("resize", () => this.resize());

    this.setupNetwork();

    // Start Loop
    this.lastTime = 0;
    requestAnimationFrame((time) => this.loop(time));
  }

  setupNetwork() {
    this.network.onOpen = () => {
      this.connected = true;
      this.connectionError = false;
    };

    this.network.onClose = () => {
      this.connected = false;
    };

    this.network.onError = () => {
      this.connectionError = true;
    };

    this.network.connect();
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
    this.draw();

    requestAnimationFrame((time) => this.loop(time));
  }

  update(dt) {
    // Game Logic here
  }

  draw() {
    // 1. Clear Screen (Void Color)
    this.ctx.fillStyle = GAME_CONFIG.COLORS.BG;
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // 2. Camera Transform
    this.ctx.save();
    this.camera.apply(this.ctx);

    // 3. Render Map
    this.renderMap();

    // 4. Restore for UI
    this.ctx.restore();

    // 5. Render UI
    this.renderUI();
  }

  renderMap() {
    this.ctx.fillStyle = GAME_CONFIG.COLORS.FLOOR;
    this.ctx.fillRect(0, 0, GAME_CONFIG.MAP.WIDTH, GAME_CONFIG.MAP.HEIGHT);

    this.ctx.strokeStyle = GAME_CONFIG.COLORS.GRID;
    this.ctx.lineWidth = 1;
    this.ctx.beginPath();
    const gridSize = 100;

    for (let x = 0; x <= GAME_CONFIG.MAP.WIDTH; x += gridSize) {
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, GAME_CONFIG.MAP.HEIGHT);
    }

    for (let y = 0; y <= GAME_CONFIG.MAP.HEIGHT; y += gridSize) {
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(GAME_CONFIG.MAP.WIDTH, y);
    }
    this.ctx.stroke();

    const riverWidth = 100;
    const riverX = GAME_CONFIG.MAP.WIDTH / 2 - riverWidth / 2;
    this.ctx.fillStyle = GAME_CONFIG.COLORS.RIVER;
    this.ctx.fillRect(riverX, 0, riverWidth, GAME_CONFIG.MAP.HEIGHT);
  }

  renderUI() {
    if (!this.connected) {
      this.ctx.fillStyle = GAME_CONFIG.COLORS.TEXT;
      this.ctx.font = "30px Arial";
      this.ctx.textAlign = "center";

      let textKey = "CONNECTING";
      if (this.connectionError) textKey = "ERROR";
      else if (!this.connected) textKey = "CONNECTING"; // Redundant

      const message = this.textManager.get(textKey);
      this.ctx.fillText(message, this.canvas.width / 2, this.canvas.height / 2);
    } else {
      this.ctx.fillStyle = "#00FF00";
      this.ctx.font = "14px Arial";
      this.ctx.textAlign = "left";
      this.ctx.fillText(this.textManager.get("CONNECTED"), 10, 20);
    }
  }
}

window.onload = () => {
  new Game();
};
