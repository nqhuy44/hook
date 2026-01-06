export const GAME_CONFIG = {
  DEBUG: true,
  LOG_LEVEL: 3, // 0: None, 1: Error, 2: Info, 3: Debug
  DEFAULT_LANG: "vi",

  HOSTS: {
    LOCAL: "ws://localhost:8080/ws",
    PROD: "wss://hook.firstdraft.sh/ws",
  },

  // Palette from draft/field.html
  COLORS: {
    // Backgrounds
    BG_DEEP: "#1e1e24",
    BG_FLOOR: "#282830",

    // Accents
    ACCENT_YELLOW: "#fdd835", // Psyduck / Gold
    ACCENT_CYAN: "#4fc3f7", // River / Mana
    ACCENT_RED: "#ef5350", // Enemy / Dire
    ACCENT_GREEN: "#66bb6a", // Ally / Radiant

    // UI
    TEXT_MAIN: "#ffffff",
    TEXT_MUTED: "#8a8a9b",

    // Map Details
    GRID_LINE: "rgba(255, 255, 255, 0.05)",
    RIVER_BORDER: "rgba(0, 0, 0, 0.1)",
    ENTITY_BORDER: "#1a1a1a",
    HP_BAR_BG: "#333333",
  },

  MAP: {
    WIDTH: 1600,
    HEIGHT: 900,
    RIVER_WIDTH: 160,
  },
};
