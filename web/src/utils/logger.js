import { GAME_CONFIG } from "../config.js";

export class Logger {
  static error(...args) {
    if (GAME_CONFIG.LOG_LEVEL >= 1) {
      console.error("[ERROR]", ...args);
    }
  }

  static info(...args) {
    if (GAME_CONFIG.LOG_LEVEL >= 2) {
      console.log("[INFO]", ...args);
    }
  }

  static debug(...args) {
    if (GAME_CONFIG.LOG_LEVEL >= 3) {
      console.log("[DEBUG]", ...args);
    }
  }

  static warn(...args) {
    if (GAME_CONFIG.LOG_LEVEL >= 1) {
      console.warn("[WARN]", ...args);
    }
  }
}
