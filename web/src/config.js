export const GAME_CONFIG = {
  DEBUG: true,
  LOG_LEVEL: 3, // 0: None, 1: Error, 2: Info, 3: Debug
  DEFAULT_LANG: "vi", // Start with Vietnamese

  HOSTS: {
    LOCAL: "ws://localhost:8080/ws",
    PROD: "wss://hook.firstdraft.sh/ws",
  },

  COLORS: {
    BG: "#202020", // Dark Grey Background (Space/Void)
    TEXT: "#FFFFFF",
    ACCENT: "#FF4500",

    // Map Colors
    FLOOR: "#394a59", // Dark Slate
    GRID: "#465a6b", // Lighter Grid
    RIVER: "#1e88e5", // River Blue
  },

  MAP: {
    WIDTH: 1600,
    HEIGHT: 900,
  },
};
