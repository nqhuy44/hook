const Input = {
    mouseX: 0,
    mouseY: 0,
    callbacks: {
        onMove: null, // (x, y)
        onSpell: null, // (key)
        onCast: null // (x, y) - Left click for targeting
    },

    init(callbacks) {
        this.callbacks = callbacks;

        window.addEventListener('mousemove', (e) => {
            this.mouseX = e.clientX;
            this.mouseY = e.clientY;
        });

        window.addEventListener('mousedown', (e) => {
            if (e.button === 2) { // Right Click
                e.preventDefault();
                if (this.callbacks.onMove) {
                    this.callbacks.onMove(e.clientX, e.clientY);
                }
            } else if (e.button === 0) { // Left Click
                if (this.callbacks.onCast) {
                    this.callbacks.onCast(e.clientX, e.clientY);
                }
            }
        });

        window.addEventListener('keydown', (e) => {
            const key = e.key.toUpperCase();
            if (['Q', 'W', 'E', 'R'].includes(key)) {
                if (this.callbacks.onSpell) {
                    this.callbacks.onSpell(key);
                }
            }
        });

        // Prevent context menu
        window.addEventListener('contextmenu', e => e.preventDefault());
    }
};
