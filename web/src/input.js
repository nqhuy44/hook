import { Logger } from "./utils/logger.js";

export class InputManager {
  constructor(canvas, network, camera) {
    this.canvas = canvas;
    this.network = network;
    this.camera = camera;

    this.setupListeners();
  }

  setupListeners() {
    // Prevent context menu on right click
    this.canvas.addEventListener("contextmenu", (e) => {
      e.preventDefault();
      this.handleRightClick(e);
    });

    // Key listeners
    window.addEventListener("keydown", (e) => {
      this.handleKeyDown(e);
    });
  }

  getGameCoordinates(clientX, clientY) {
    // Canvas is full screen, so clientX/Y is relative to the viewport.
    // We need to apply Camera offset to get World coordinates.
    // WorldX = ClientX + CameraX - ScreenCenterX
    // But for now, let's assume Camera is TOP-LEFT linked or Centered.

    // Let's defer to Camera logic if we have it, or just pass simple coords
    // and let Game/Camera class handle translation.

    // BUT, we need to send World Coordinates to server.
    const rect = this.canvas.getBoundingClientRect();
    const mouseX = clientX - rect.left;
    const mouseY = clientY - rect.top;

    return this.camera.screenToWorld(mouseX, mouseY);
  }

  handleRightClick(e) {
    const { x, y } = this.getGameCoordinates(e.clientX, e.clientY);

    Logger.debug(`Input Move: ${x.toFixed(0)}, ${y.toFixed(0)}`);

    this.network.send("input", {
      type: "move",
      x: x,
      y: y,
    });
  }

  handleKeyDown(e) {
    const key = e.key.toLowerCase();

    let skillIdx = -1;
    if (key === "q") skillIdx = 0;
    if (key === "w") skillIdx = 1;

    if (skillIdx !== -1) {
      // Needed: Mouse position for aiming?
      // Usually skills like Hook shoot towards mouse.
      // We might need to track mouse position constantly to send it with skill.
      // For now, let's just send the keyDown event and maybe Mouse Position if we track it.
      // Simplified: Just send skill signal, assume Server or next Packet uses current mouse?
      // Or better: Pass current mouse pos.

      // Let's implement mouse tracking quickly
      if (!this.lastMousePos) {
        this.lastMousePos = { x: 0, y: 0 };
      }

      const { x, y } = this.lastMousePos;

      Logger.debug(
        `Input Skill: ${skillIdx} at ${x.toFixed(0)}, ${y.toFixed(0)}`
      );

      this.network.send("input", {
        type: "skill",
        skillIdx: skillIdx,
        x: x,
        y: y,
      });
    }
  }
}

// Attach generic mouse move tracker for aiming
InputManager.prototype.setupMouseTracking = function () {
  window.addEventListener("mousemove", (e) => {
    const rect = this.canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;
    const worldPos = this.camera.screenToWorld(mouseX, mouseY);
    this.lastMousePos = worldPos;
  });
};
