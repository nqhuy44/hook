import { GAME_CONFIG } from "./config.js";

export class Camera {
  constructor(canvas) {
    this.canvas = canvas;
    this.x = 0;
    this.y = 0;
  }

  // Center camera on the map (centering the map in the screen)
  centerOnMap() {
    // Map center
    const mapCX = GAME_CONFIG.MAP.WIDTH / 2;
    const mapCY = GAME_CONFIG.MAP.HEIGHT / 2;

    // Screen center (relative to world) is where looking at.
    // Actually Camera X,Y usually top-left of the viewport in World Space.

    // If we want the Map Center to be at Screen Center:
    // Screen Center X = CanvasWidth / 2
    // World Pos at Screen Center = MapWidth / 2

    // Camera X = WorldPos - ScreenCenter
    this.x = mapCX - this.canvas.width / 2;
    this.y = mapCY - this.canvas.height / 2;
  }

  screenToWorld(screenX, screenY) {
    return {
      x: screenX + this.x,
      y: screenY + this.y,
    };
  }

  worldToScreen(worldX, worldY) {
    return {
      x: worldX - this.x,
      y: worldY - this.y,
    };
  }

  apply(ctx) {
    ctx.translate(-this.x, -this.y);
  }
}
