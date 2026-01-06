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
    // Auto-detect protocol
    const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";

    // Determine host.
    // If we are developing locally (file:// or localhost), we might want to hardcode or default to localhost:8080 if not otherwise specified.
    // But the requirements say:
    // Local: ws://localhost:8080/ws
    // Production: wss://hook.firstdraft.sh/ws

    let host = "localhost:8080";
    if (
      window.location.hostname !== "localhost" &&
      window.location.hostname !== "127.0.0.1" &&
      window.location.protocol !== "file:"
    ) {
      host = "hook.firstdraft.sh";
    }

    // If we are just opening index.html from file system, usually we want localhost.
    if (window.location.protocol === "file:") {
      // Force local dev environment defaults
      this.connectToUrl("ws://localhost:8080/ws");
    } else {
      this.connectToUrl(`${protocol}//${host}/ws`);
    }
  }

  connectToUrl(url) {
    console.log(`Connecting to ${url}...`);
    this.socket = new WebSocket(url);

    this.socket.onopen = (event) => {
      console.log("socket open");
      this.isConnected = true;
      if (this.onOpen) this.onOpen(event);
    };

    this.socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        // Debug log
        console.log("Received:", data);

        if (this.onMessage) this.onMessage(data);
      } catch (e) {
        console.error("Error parsing message:", e, event.data);
      }
    };

    this.socket.onclose = (event) => {
      console.log("socket closed");
      this.isConnected = false;
      if (this.onClose) this.onClose(event);
    };

    this.socket.onerror = (event) => {
      console.error("socket error", event);
      if (this.onError) this.onError(event);
    };
  }

  send(type, payload) {
    if (!this.isConnected) {
      console.warn("Cannot send message, socket not connected");
      return;
    }

    const packet = {
      type: type,
      payload: payload,
    };

    this.socket.send(JSON.stringify(packet));
  }
}
