import { Logger } from "./utils/logger.js";

export class InputManager {
  constructor(canvas, network, camera) {
    this.canvas = canvas;
    this.network = network;
    this.camera = camera;

    // Local state
    this.mouseScreen = { x: 0, y: 0 };
    this.mouseWorld = { x: 0, y: 0 };

    this.setupListeners();
  }

  setupListeners() {
    // Track Mouse
    window.addEventListener("mousemove", (e) => {
      const rect = this.canvas.getBoundingClientRect();
      this.mouseScreen.x = e.clientX - rect.left;
      this.mouseScreen.y = e.clientY - rect.top;

      // Update World Pos immediately
      this.mouseWorld = this.camera.screenToWorld(
        this.mouseScreen.x,
        this.mouseScreen.y
      );
    });

    // 1. Movement (Right Click)
    this.canvas.addEventListener("contextmenu", (e) => {
      e.preventDefault();
      this.handleMove();
    });

    // 2. Skills (Keyboard)
    window.addEventListener("keydown", (e) => {
      if (e.target.tagName === "INPUT") return; // Ignore if typing in chat
      this.handleKeyDown(e);
    });
  }

  handleMove() {
    const { x, y } = this.mouseWorld;

    Logger.debug(`[Input] Move -> ${x.toFixed(0)}, ${y.toFixed(0)}`);

    this.network.send("input", {
      type: "move",
      x: x,
      y: y,
      targetID: null, // For unit targeting later
    });
  }

  handleKeyDown(e) {
    const key = e.key.toLowerCase();
    let skillIdx = -1;

    if (key === "q") skillIdx = 0; // Hook
    if (key === "w") skillIdx = 1; // Rot/Dismember

    if (skillIdx !== -1) {
      const { x, y } = this.mouseWorld;
      Logger.debug(
        `[Input] Skill ${skillIdx} -> ${x.toFixed(0)}, ${y.toFixed(0)}`
      );

      this.network.send("input", {
        type: "skill",
        skillIdx: skillIdx,
        x: x,
        y: y,
      });
    }
  }

  // Getter for looking direction etc.
  getMouseWorld() {
    return this.mouseWorld;
  }
}
