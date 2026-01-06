import { GAME_CONFIG } from "../config.js";
import { Logger } from "./logger.js";

const LOCALES = {
  en: {
    GAME_TITLE: "Hook it!",
    CONNECTING: "Connecting to server...",
    CONNECTED: "Connected!",
    DISCONNECTED: "Disconnected from server.",
    ERROR: "Connection Error!",
  },
  vi: {
    GAME_TITLE: "Kéo nó!",
    CONNECTING: "Đang kết nối máy chủ...",
    CONNECTED: "Đã kết nối!",
    DISCONNECTED: "Mất kết nối máy chủ.",
    ERROR: "Lỗi kết nối!",
  },
};

export class TextManager {
  constructor() {
    this.lang = GAME_CONFIG.DEFAULT_LANG;
    if (!LOCALES[this.lang]) {
      Logger.warn(`Language ${this.lang} not found, falling back to 'en'.`);
      this.lang = "en";
    }
  }

  get(key) {
    const dict = LOCALES[this.lang];
    return dict[key] || key;
  }

  setLanguage(lang) {
    if (LOCALES[lang]) {
      this.lang = lang;
    } else {
      Logger.warn(`Language ${lang} not supported.`);
    }
  }
}
