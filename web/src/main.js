import { NetworkManager } from "./network.js";

class Game {
  constructor() {
    this.canvas = document.getElementById("gameCanvas");
    this.ctx = this.canvas.getContext("2d", { alpha: false }); // Optimize for no transparency if possible
    this.network = new NetworkManager();

    this.connected = false;

    this.resize();
    window.addEventListener("resize", () => this.resize());

    this.setupNetwork();

    // Start loop
    this.lastTime = 0;
    requestAnimationFrame((time) => this.loop(time));
  }

  setupNetwork() {
    this.network.onOpen = () => {
      console.log("Connected to Server!");
      this.connected = true;
    };

    this.network.connect();
  }

  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  }

  loop(timestamp) {
    // Calculate dt if needed
    const dt = (timestamp - this.lastTime) / 1000;
    this.lastTime = timestamp;

    this.update(dt);
    this.draw();

    requestAnimationFrame((time) => this.loop(time));
  }

  update(dt) {
    // Update game logic here
  }

  draw() {
    // Clear screen
    this.ctx.fillStyle = "#000000";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw status text
    this.ctx.fillStyle = "#FFFFFF";
    this.ctx.font = "30px Arial";
    this.ctx.textAlign = "center";

    let text = "Connecting...";
    if (this.connected) {
      text = "Connected to Server!";
    }

    this.ctx.fillText(text, this.canvas.width / 2, this.canvas.height / 2);
  }
}

// Start the game when the window loads
window.onload = () => {
  const game = new Game();
};
