# HooK Godot Client

This directory contains the Godot 4.5.1 project for the frontend of the HooK game.

## Prerequisites

- Godot Engine 4.5.1 (or compatible 4.x version)

## How to Run

1.  **Start the Backend**:
    Ensure the Go server is running in the root directory:
    ```bash
    go run .
    ```

2.  **Open Godot**:
    - Launch Godot.
    - Click **Import**.
    - Navigate to this `frontend` folder.
    - Click **Import & Edit**.

3.  **Play**:
    - Press `F5` or the **Play** button in the top right.
    - Enter a Name and click **Create Room** (or Join).
    - If hosting, click **START GAME**.

## Structure

- `scripts/`: Contains all GDScript logic.
    - `network_manager.gd`: Autoloaded WebSocket client.
    - `lobby.gd`: UI for the lobby.
    - `game.gd`: Main game loop and state management.
    - `entity.gd`: Visuals for players/bots.
- `scenes/`: Contains scenes.
    - `main.tscn`: The entry point (Manages switching between Lobby and Game).
