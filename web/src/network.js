import { GAME_CONFIG } from "./config.js";
import { Logger } from "./utils/logger.js";

export class NetworkManager {
  constructor() {
    this.socket = null;
    this.isConnected = false;

    // Event callbacks
    this.onOpen = null;
    this.onMessage = null;
    this.onClose = null;
    this.onError = null;
  }

  connect() {
    let url = GAME_CONFIG.HOSTS.LOCAL;

    // Auto-detect production
    if (
      window.location.hostname !== "localhost" &&
      window.location.hostname !== "127.0.0.1" &&
      window.location.protocol !== "file:"
    ) {
      url = GAME_CONFIG.HOSTS.PROD;
    }

    if (window.location.protocol === "https:" && url.startsWith("ws:")) {
      url = url.replace("ws:", "wss:");
    }

    Logger.info(`Connecting to ${url}...`);
    this.socket = new WebSocket(url);

    this.socket.onopen = (event) => {
      Logger.info("WebSocket Open");
      this.isConnected = true;
      if (this.onOpen) this.onOpen(event);
    };

    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        Logger.debug("Received:", data);
        if (this.onMessage) this.onMessage(data);
      } catch (e) {
        Logger.error("Error parsing message:", e, event.data);
      }
    };

    this.socket.onclose = (event) => {
      Logger.info("WebSocket Closed");
      this.isConnected = false;
      if (this.onClose) this.onClose(event);
    };

    this.socket.onerror = (event) => {
      Logger.error("WebSocket Error", event);
      if (this.onError) this.onError(event);
    };
  }

  send(type, payload) {
    if (!this.isConnected) {
      Logger.warn("Cannot send message, socket not connected");
      return;
    }

    const packet = {
      type: type,
      payload: payload,
    };

    this.socket.send(JSON.stringify(packet));
  }
}
