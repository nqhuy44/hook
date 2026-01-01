let canvas;
let ctx;
let ws;
let myId = null;
let isHost = false;
let gameState = {};
let camera = { x: 0, y: 0 };
let myHero = null;
let initialized = false;
let skillTargeting = -1;
let isDragging = false;
let lastDrag = { x: 0, y: 0 };
let particles = [];

// --- 10 UNIQUE MODELS ---
const MODELS = [
    { id: "pudge", name: "Pudge", color: "#ffccaa" },
    { id: "tech", name: "Tech", color: "#00ccff" },
    { id: "nature", name: "Nature", color: "#66ff66" },
    { id: "void", name: "Void", color: "#aa00ff" },
    { id: "inferno", name: "Inferno", color: "#ff4400" },
    { id: "glacial", name: "Glacial", color: "#aaddff" },
    { id: "holy", name: "Holy", color: "#ffd700" },
    { id: "shadow", name: "Shadow", color: "#333333" },
    { id: "mecha", name: "Mecha", color: "#888888" },
    { id: "cosmic", name: "Cosmic", color: "#ffffff" }
];
let selectedModel = MODELS[0].id;

// DEBUG: Global Error Handler
window.onerror = function(msg, url, line, col, error) {
   alert("JS Error: " + msg + "\nLine: " + line);
   return false;
};

document.addEventListener("DOMContentLoaded", () => {
    canvas = document.getElementById('gameCanvas');
    if (!canvas) {
        console.error("Canvas element not found!");
        return;
    }
    ctx = canvas.getContext('2d');

    // Connect
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${window.location.host}/ws`);

    ws.onmessage = (e) => {
        const msg = JSON.parse(e.data);
        if(msg.type === "room_joined") {
            myId = msg.id; isHost = msg.is_host;
            showScreen("lobby-screen");
            document.getElementById("lobby-title").innerText = "CODE: " + msg.code;
            if(isHost) document.getElementById("start-btn").classList.remove("hidden");
            initLobbySelector();
        } else if(msg.type === "lobby_update") {
            renderLobby(msg.players);
        } else if(msg.type === "game_started") {
            document.getElementById("lobby-screen").classList.add("hidden");
            document.getElementById("hud-container").classList.remove("hidden");
            document.getElementById("gameCanvas").classList.remove("hidden");
            resizeCanvas();
            requestAnimationFrame(loop);
        } else if(msg.type === "game_state" || msg.type === "game_update") {
            // Buffer for interpolation
            const s = msg.payload || msg.state;
            serverUpdates.push({ state: s, time: Date.now() });
            if(serverUpdates.length > 5) serverUpdates.shift();
            
            // Still process events immediately (like Feed/Game Over)
            handleGameEvents(s);
        } else if(msg.type === "error") { 
            alert(msg.message); 
        }
    };
});

let serverUpdates = [];
const RENDER_DELAY = 100; // ms (ServerTick=33ms, so 3 frames buffer)

let lastServerFeed = [];

function handleGameEvents(s) {
     // Robust Feed Deduping
     if(s.feed) {
        const newItems = getNewItems(lastServerFeed, s.feed);
        if(newItems.length > 0) {
            const f = document.getElementById("kill-feed");
            newItems.forEach(msg => {
                const d = document.createElement("div"); d.className="feed-item"; 
                d.innerText = msg;
                f.appendChild(d);
                setTimeout(()=>d.remove(), 5000);
            });
        }
        lastServerFeed = s.feed;
        gameState.feed = s.feed; // Keep synced
     }

     if(s.game_over && !gameState.game_over) {
         // Trigger once if needed
     }
     
     // Update Score/Time/Winner
     if(s.score) {
         gameState.score = s.score;
         // DIRECT DOM UPDATE (Bypassing potential HUD loop issues)
         const sc1 = document.getElementById("sc-1");
         const sc2 = document.getElementById("sc-2");
         const v1 = (s.score["1"]!==undefined) ? s.score["1"] : (s.score[1]||0);
         const v2 = (s.score["2"]!==undefined) ? s.score["2"] : (s.score[2]||0);
         if(sc1) sc1.innerText = v1;
         if(sc2) sc2.innerText = v2;
         // Debug log once per 100 updates to verify connection (optional, redundant now)
     }
     if(s.time_remaining !== undefined) {
         gameState.time_remaining = s.time_remaining;
         // DIRECT DOM UPDATE
         const totalSec = Math.max(0, Math.floor(s.time_remaining));
         const m = Math.floor(totalSec / 60);
         const ss = totalSec % 60;
         const tEl = document.getElementById('timer-display');
         if(tEl) tEl.innerText = `${m}:${ss<10?'0':''}${ss}`;
     }
     
     if(s.winner) gameState.winner = s.winner;
     if(s.game_over !== undefined) {
         gameState.game_over = s.game_over;
         // Trigger immediately
         if(s.game_over) {
             const gos = document.getElementById('game-over-screen');
             if(gos) {
                 gos.style.display="flex"; gos.style.pointerEvents="auto";
                 const wt = document.getElementById('winner-text');
                 if(wt) {
                    wt.innerText = s.winner + " VICTORY";
                    if(s.winner==="RADIANT") wt.style.color="#00e676";
                    else if(s.winner==="DIRE") wt.style.color="#d50000";
                 }
             }
         }
     }
}

function getNewItems(oldArr, newArr) {
    if(!oldArr || oldArr.length === 0) return newArr;
    if(!newArr || newArr.length === 0) return [];
    
    // Check for overlap
    // Iterate possible overlap lengths
    // Max overlap is min(old.length, new.length)
    // We want longest suffix of old that matches prefix of new
    
    // Quick check: identical?
    if (oldArr.length === newArr.length && oldArr.every((v,i)=>v===newArr[i])) return [];
    
    for (let len = Math.min(oldArr.length, newArr.length); len > 0; len--) {
        // Check if suffix of old (size len) == prefix of new (size len)
        // old: [..., A, B, C]
        // new: [A, B, C, ...]
        
        let match = true;
        for (let i = 0; i < len; i++) {
            if (oldArr[oldArr.length - len + i] !== newArr[i]) {
                match = false;
                break;
            }
        }
        
        if (match) {
            // Found overlap! New items are everything after len
            return newArr.slice(len);
        }
    }
    
    // No overlap found, assume all new (or gap occurred)
    return newArr;
}

function initLobbySelector() {
    const container = document.getElementById('lobby-model-selector');
    if (!container) return;
    container.innerHTML = "";
    MODELS.forEach(m => {
        const d = document.createElement("div");
        d.style.width = "40px"; d.style.height = "40px";
        d.style.borderRadius = "50%";
        d.style.background = "#222";
        d.style.border = "2px solid #555";
        d.style.cursor = "pointer";
        d.style.position = "relative";
        d.title = m.name;
        
        // Mini Preview Canvas
        const c = document.createElement("canvas");
        c.width = 40; c.height = 40;
        d.appendChild(c);
        
        // Render Preview
        const cx = c.getContext("2d");
        cx.translate(20, 20);
        drawModel(cx, m.id, 15, m.color, 0); // No rotation for preview

        d.onclick = () => {
            selectedModel = m.id;
            // Send Change
            if(ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({
                    type: "change_avatar",
                    payload: { avatar_id: m.id } 
                }));
            }
            // Update UI
            document.querySelectorAll("#lobby-model-selector > div").forEach(el => el.style.borderColor = "#555");
            d.style.borderColor = "#00e676";
        };
        
        if (m.id === selectedModel) d.style.borderColor = "#00e676";
        container.appendChild(d);
    });
}

function createRoom() { 
    if(ws && ws.readyState === WebSocket.OPEN)
        ws.send(JSON.stringify({ type: "create_room", payload: { name: document.getElementById("pname").value || "Player", avatar_id: selectedModel } })); 
}
function joinRoom() { 
    if(ws && ws.readyState === WebSocket.OPEN)
        ws.send(JSON.stringify({ type: "join_room", payload: { code: document.getElementById("room-code").value, name: document.getElementById("pname").value || "Player", avatar_id: selectedModel } })); 
}
function switchTeam() { if(ws) ws.send(JSON.stringify({ type: "switch_team", payload: {} })); }
function startGame() { if(ws) ws.send(JSON.stringify({ type: "start_game", payload: {} })); }

function renderLobby(players) {
    const list1 = document.getElementById("list-1");
    const list2 = document.getElementById("list-2");
    list1.innerHTML = ""; 
    list2.innerHTML = "";

    players.forEach(p => {
        const d = document.createElement("div"); 
        d.className = "player-item";
        
        // Preview Wrapper
        const preview = document.createElement("div");
        preview.className = "lobby-model-preview";
        
        // Canvas
        const c = document.createElement("canvas");
        c.width = 30; c.height = 30;
        const cx = c.getContext("2d");
        cx.translate(15, 15);
        drawModel(cx, p.avatar_id, 12, p.color, 0); // Correctly draw immediately
        
        preview.appendChild(c);
        d.appendChild(preview);
        
        // Name
        const nameSpan = document.createElement("span");
        nameSpan.innerText = p.name;
        d.appendChild(nameSpan);

        if(p.team === 1) list1.appendChild(d); 
        else list2.appendChild(d);
    });
}

function showScreen(id) {
    document.querySelectorAll(".screen").forEach(s => s.classList.add("hidden"));
    const el = document.getElementById(id);
    if(el) el.classList.remove("hidden");
    
    // Safety: If showing lobby, hide HUD/Canvas
    if(id === "lobby-screen" || id === "menu-screen") {
        document.getElementById("hud-container").classList.add("hidden");
        document.getElementById("gameCanvas").classList.add("hidden");
    }
}

// handleGameUpdate removed (replaced by handleGameEvents and loop interpolation)

function updateHUD() {
    // ----------------------------------------
    // 1. GLOBAL UPDATES (Score, Timer, Game Over)
    // ----------------------------------------
    
    // Timer
    if (gameState.time_remaining !== undefined) {
        const tEl = document.getElementById('timer-display');
        if(tEl) {
            const totalSec = Math.max(0, Math.floor(gameState.time_remaining));
            const m = Math.floor(totalSec / 60);
            const s = totalSec % 60;
            tEl.innerText = `${m}:${s<10?'0':''}${s}`;
        }
    }

    // Score
    if(gameState.score) {
        const sc1 = document.getElementById("sc-1");
        const sc2 = document.getElementById("sc-2");
        const v1 = (gameState.score["1"]!==undefined) ? gameState.score["1"] : (gameState.score[1]||0);
        const v2 = (gameState.score["2"]!==undefined) ? gameState.score["2"] : (gameState.score[2]||0);
        if(sc1) sc1.innerText = v1;
        if(sc2) sc2.innerText = v2;
    }

    // Game Over
    if (gameState.game_over) {
        const gos = document.getElementById('game-over-screen');
        if(gos) {
            gos.style.display="flex"; gos.style.pointerEvents="auto";
            const wt=document.getElementById('winner-text');
            if(wt) {
               wt.innerText = gameState.winner + " VICTORY";
               wt.style.color = (gameState.winner==="RADIANT") ? "#00e676" : ((gameState.winner==="DIRE") ? "#d50000" : "#fff");
            }
        }
    } else {
        const gos = document.getElementById('game-over-screen');
        if(gos) gos.style.display="none";
    }

    // ----------------------------------------
    // 2. PLAYER UPDATES
    // ----------------------------------------
    
    // Safety & Recovery
    if(!gameState.entities) return;
    
    // If lost ID, try to find by Name
    if(!myId || !gameState.entities[myId]) {
        const myName = document.getElementById("pname").value || "Player";
        const found = Object.values(gameState.entities).find(e => e.name === myName);
        if(found) {
            myId = found.id;
        } else {
            return; // Hero not found yet
        }
    }

    const hero = gameState.entities[myId];
    myHero = hero; // Sync global reference

    try {
        // Name
        const nEl = document.getElementById("hero-name");
        if(nEl) nEl.innerText = hero.name;

        // Bars
        const hpPct = (hero.hp / hero.max_hp) * 100;
        const mpPct = (hero.mana / hero.max_mana) * 100;
        
        document.getElementById("hp-bar").style.width = hpPct + "%";
        document.getElementById("hp-text").innerText = `${Math.floor(hero.hp)} / ${hero.max_hp}`;
        document.getElementById("mp-bar").style.width = mpPct + "%";
        document.getElementById("mp-text").innerText = `${Math.floor(hero.mana)} / ${hero.max_mana}`;

        document.getElementById("dead-screen").style.display = hero.dead ? "flex" : "none";
        document.getElementById("wrong-side").style.display = hero.territory_burn ? "block" : "none";

        // Avatar
        const pCanvas = document.createElement("canvas");
        pCanvas.width = 90; pCanvas.height = 90;
        const pctx = pCanvas.getContext("2d");
        pctx.translate(45, 45);
        const aid = hero.avatar_id || "pudge";
        drawModel(pctx, aid, 35, hero.color, -Math.PI/2);
        document.getElementById("hud-portrait").style.backgroundImage = `url(${pCanvas.toDataURL()})`;

        // Skills
        const skillsContainer = document.getElementById("skills");
        if(skillsContainer) {
            // Rebuild if needed
            if(skillsContainer.children.length !== (hero.skills || []).length) {
                skillsContainer.innerHTML = "";
                if(hero.skills) {
                    hero.skills.forEach((s, i) => {
                        const d = document.createElement("div");
                        d.className = "skill-box";
                        d.id = `s-${i}`;
                        d.innerHTML = `<div class="skill-key">${s.key}</div><div class="skill-name">${s.name}</div><div class="cd-overlay" id="cd-${i}"></div>`;
                        d.onclick = () => { if(s.type==='toggle') sendInput("skill", {skillIdx:i}); };
                        skillsContainer.appendChild(d);
                    });
                }
            }

            // Update Status
            if(hero.skills) {
                hero.skills.forEach((s, i) => {
                    const el = document.getElementById(`s-${i}`);
                    if(el) el.classList.toggle("active", s.active===true);
                    const cd = document.getElementById(`cd-${i}`);
                    if(cd) cd.style.height = (s.cooldown / s.max_cd * 100) + "%";
                });
            }
        }
    } catch(e) {
        console.error("HUD Rendering Error:", e);
    }
}

function resizeCanvas() { 
    if(!canvas) return; 
    canvas.width = window.innerWidth; 
    canvas.height = window.innerHeight; 
}
window.addEventListener('resize', resizeCanvas);
window.addEventListener("keydown", e => {
    if(!myHero || myHero.dead) return;
    const k=['q','w','e','r']; const i=k.indexOf(e.key.toLowerCase());
    if(i>-1) { if(myHero.skills[i].type==='toggle') sendInput("skill", {skillIdx:i}); else { if (skillTargeting === i) { skillTargeting = -1; document.body.classList.remove('targeting'); } else { skillTargeting = i; document.body.classList.add('targeting'); } } }
});
window.addEventListener("mousedown", e => {
    const tagName = e.target.tagName.toLowerCase();
    if(tagName === "input" || tagName === "button") return; // Allow UI interaction
    if(e.button===0) { if(skillTargeting!==-1) { const {x,y}=getMouse(e); sendInput("skill", {skillIdx:skillTargeting, x, y, targetID:getTarget(x,y)}); skillTargeting=-1; document.body.classList.remove('targeting'); } else { isDragging=true; lastDrag={x:e.clientX,y:e.clientY}; } }
    else if(e.button===2) { skillTargeting=-1; document.body.classList.remove('targeting'); const {x,y}=getMouse(e); const t=getTarget(x,y); sendInput(t?"attack":"move", {x, y, targetID:t}); }
});
window.addEventListener("mouseup", ()=>isDragging=false);
window.addEventListener("mousemove", e=>{ if(isDragging){ camera.x -= e.clientX-lastDrag.x; camera.y -= e.clientY-lastDrag.y; lastDrag={x:e.clientX,y:e.clientY}; } });
window.addEventListener("contextmenu", e=>e.preventDefault());
function sendInput(type, data) { if(ws && ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({type: "input", payload: {type, ...data}})); }
function getMouse(e) { return {x:e.clientX+camera.x, y:e.clientY+camera.y}; }
function getTarget(x,y) { for(let id in gameState.entities) { const e=gameState.entities[id]; if(e.id!==myId && Math.hypot(e.pos.x-x, e.pos.y-y) < e.radius+20) return e.id; } return ""; }

function loop() {
    if (!ctx) return;
    
    // --- INTERPOLATION ---
    const now = Date.now();
    const renderTime = now - RENDER_DELAY;
    
    // Find two frames surrounding renderTime
    let u1 = null, u2 = null;
    for (let i = 0; i < serverUpdates.length - 1; i++) {
        if (serverUpdates[i].time <= renderTime && serverUpdates[i+1].time >= renderTime) {
            u1 = serverUpdates[i];
            u2 = serverUpdates[i+1];
            break;
        }
    }
    
    // Fallback: If no valid pair (lag or startup), render latest
    let renderState = gameState; 
    if (u1 && u2) {
        const total = u2.time - u1.time;
        const elapsed = renderTime - u1.time;
        const t = elapsed / total;
        
        renderState = { ...u2.state }; // Clone base
        renderState.entities = {};
        
        // Interpolate Entities
        for (const id in u2.state.entities) {
            const e2 = u2.state.entities[id];
            const e1 = u1.state.entities[id];
            
            if (e1 && e2 && !e2.dead && !e1.dead) { // Only interpolate if alive in both
                // Simple Lerp
                renderState.entities[id] = {
                    ...e2,
                    pos: {
                        x: e1.pos.x + (e2.pos.x - e1.pos.x) * t,
                        y: e1.pos.y + (e2.pos.y - e1.pos.y) * t
                    },
                    rotation: e1.rotation + (e2.rotation - e1.rotation) * t 
                    // Note: Rotation lerp needs shortest path check, but this is okay for small steps
                };
            } else {
                renderState.entities[id] = e2; // Startup/Spawn/Death
            }
        }
        
        // Projectiles (Linear movement, safe to lerp)
        renderState.projectiles = u2.state.projectiles.map((p2, i) => {
            // Finding matching projectile across frames is hard without ID in array
            // But usually array order is preserved or replaced. 
            // For now, raw render p2 to avoid ghost projectiles.
            return p2; 
        });
    } else if (serverUpdates.length > 0) {
        renderState = serverUpdates[serverUpdates.length - 1].state;
    }
    
    // Update Global for HUD reference
    gameState.entities = renderState.entities;
    if(myId && gameState.entities) myHero = gameState.entities[myId];

    // Clear
    ctx.fillStyle = "#050b14";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.save();
    
    // Camera
    if (myHero) {
        camera.x = myHero.pos.x - canvas.width / 2;
        camera.y = myHero.pos.y - canvas.height / 2;
    }
    // Clamp Camera
    camera.x = Math.max(0, Math.min(camera.x, 1600 - canvas.width));
    camera.y = Math.max(0, Math.min(camera.y, 900 - canvas.height));
    
    ctx.translate(-camera.x, -camera.y);

    drawMap();
    drawUnits(renderState); // Pass interpolated state
    drawProjectiles(renderState); // Pass interpolated state
    drawAnimations(); // Particles are client-side, no state needed

    ctx.restore();
    requestAnimationFrame(loop);
}

function drawMap() {
    const rx = 720; ctx.fillStyle = '#02050a'; ctx.fillRect(rx, 0, 160, 900);
    // River Glow
    ctx.shadowBlur = 20; ctx.shadowColor = '#00aaff'; ctx.strokeStyle = '#00ccff'; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.moveTo(rx, 0); ctx.lineTo(rx, 900); ctx.moveTo(rx+160, 0); ctx.lineTo(rx+160, 900); ctx.stroke(); ctx.shadowBlur = 0;
    
    // Border
    ctx.strokeStyle = '#336699'; ctx.lineWidth = 10; ctx.strokeRect(0, 0, 1600, 900);
}

function drawUnits(state) {
    if(!state) return;
    const entities = state.entities;
    for (const id in entities) {
        const e = entities[id]; if(e.dead) continue;
        if(e.skills && e.skills[1] && e.skills[1].active) { ctx.fillStyle="rgba(0,255,100,0.15)"; ctx.beginPath(); ctx.arc(e.pos.x,e.pos.y,60,0,Math.PI*2); ctx.fill(); }
        
        ctx.save(); ctx.translate(e.pos.x, e.pos.y); ctx.rotate(e.rotation);
        
        // --- 10 Unique Models Rendering ---
        const modelId = e.avatar_id || "pudge";
        drawModel(ctx, modelId, e.radius, e.color, e.rotation);
        
        ctx.restore();

        // HP/Name
        ctx.fillStyle="white"; ctx.font="bold 16px Rajdhani"; ctx.textAlign="center"; ctx.fillText(e.name, e.pos.x, e.pos.y-40);
        const barW = 60; const pct=e.hp/e.max_hp; 
        ctx.fillStyle="black"; ctx.fillRect(e.pos.x-barW/2, e.pos.y-e.radius-15, barW, 5);
        ctx.fillStyle=e.team===(myHero?myHero.team:1)?"#00e676":"#d50000"; ctx.fillRect(e.pos.x-barW/2, e.pos.y-e.radius-15, barW*pct, 5);
    }
    
    // Projectiles
    if (state.projectiles) {
        state.projectiles.forEach(p => {
            ctx.save();
            ctx.translate(p.pos.x, p.pos.y);
            ctx.rotate(p.rotation);
            
            // Draw Hook Head
            ctx.fillStyle = "#888"; 
            ctx.beginPath(); ctx.moveTo(10,0); ctx.lineTo(-10,10); ctx.lineTo(-5,0); ctx.lineTo(-10,-10); ctx.fill();
            
            ctx.restore();

            // Draw Chain
            if(state.entities[p.from_id]) {
                 const owner = state.entities[p.from_id];
                 ctx.beginPath(); ctx.moveTo(owner.pos.x, owner.pos.y); ctx.lineTo(p.pos.x, p.pos.y);
                 ctx.strokeStyle="#555"; ctx.lineWidth=4; ctx.stroke();
            }
        });
    }
}

// --- FANCY MODELS (ANIMAL EDITION) ---
function drawModel(c, id, r, color, rot) {
    c.save();
    
    // --- BOT MODEL (Team Minion) ---
    if (id === "bot_basic") {
        c.fillStyle = color || "#777"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        c.strokeStyle = "#fff"; c.lineWidth = 1; c.stroke();
        // Eye
        c.fillStyle = "#fff"; c.beginPath(); c.arc(0, -r*0.2, r*0.4, 0, Math.PI*2); c.fill();
        c.fillStyle = "#000"; c.beginPath(); c.arc(0, -r*0.2, r*0.15, 0, Math.PI*2); c.fill();
        c.strokeStyle = "#000"; c.lineWidth = 2; c.beginPath(); c.moveTo(-r*0.3, -r*0.5); c.lineTo(r*0.3, -r*0.5); c.stroke();
        c.restore(); return;
    }

    // --- ANIMAL HEROES ---
    if (id === "pudge") {
        // PIG (Chef)
        c.fillStyle = "#f8bbd0"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill(); // Pink Body
        // Snout
        c.fillStyle = "#f48fb1"; c.beginPath(); c.ellipse(0, r*0.2, r*0.35, r*0.25, 0, 0, Math.PI*2); c.fill();
        c.fillStyle = "#880e4f"; c.beginPath(); c.arc(-r*0.15, r*0.2, r*0.08, 0, Math.PI*2); c.arc(r*0.15, r*0.2, r*0.08, 0, Math.PI*2); c.fill();
        // Ears
        c.fillStyle = "#f8bbd0"; c.beginPath(); c.moveTo(-r*0.8, -r*0.5); c.lineTo(-r, -r*1.2); c.lineTo(-r*0.2, -r*0.9); c.fill();
        c.beginPath(); c.moveTo(r*0.8, -r*0.5); c.lineTo(r, -r*1.2); c.lineTo(r*0.2, -r*0.9); c.fill();
        // Chef Hat
        c.fillStyle = "#fff"; c.beginPath(); c.rect(-r*0.4, -r*1.3, r*0.8, r*0.6); c.fill();
        c.beginPath(); c.arc(0, -r*1.3, r*0.55, Math.PI, 0); c.fill();
    } 
    else if (id === "tech") {
        // MOUSE (VR Gamer)
        c.fillStyle = "#90a4ae"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Big Round Ears
        c.beginPath(); c.arc(-r*0.9, -r*0.5, r*0.5, 0, Math.PI*2); c.arc(r*0.9, -r*0.5, r*0.5, 0, Math.PI*2); c.fill();
        // VR Headset
        c.fillStyle = "#111"; c.fillRect(-r*0.6, -r*0.3, r*1.2, r*0.6);
        c.fillStyle = "#00e676"; c.fillRect(r*0.3, -r*0.2, r*0.1, r*0.4); 
    } 
    else if (id === "nature") {
        // FROG (Flower)
        c.fillStyle = "#4caf50"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Eyes Pop
        c.fillStyle = "#4caf50"; c.beginPath(); c.arc(-r*0.5, -r*0.6, r*0.3, 0, Math.PI*2); c.arc(r*0.5, -r*0.6, r*0.3, 0, Math.PI*2); c.fill();
        c.fillStyle = "#fff"; c.beginPath(); c.arc(-r*0.5, -r*0.6, r*0.15, 0, Math.PI*2); c.arc(r*0.5, -r*0.6, r*0.15, 0, Math.PI*2); c.fill();
        // Flower Hat
        c.fillStyle = "#ffeb3b"; c.beginPath(); c.arc(0, -r*0.8, r*0.3, 0, Math.PI*2); c.fill();
        c.fillStyle = "#e91e63"; 
        for(let i=0;i<5;i++) { c.beginPath(); c.arc(Math.cos(i*1.25)*r*0.5, -r*0.8+Math.sin(i*1.25)*r*0.5, r*0.2, 0, Math.PI*2); c.fill(); }
    } 
    else if (id === "void") {
        // BAT (Sunglasses)
        c.fillStyle = "#4527a0"; c.beginPath(); c.arc(0,0,r*0.8,0,Math.PI*2); c.fill();
        // Wings
        c.beginPath(); c.moveTo(-r*0.8,0); c.lineTo(-r*1.8, -r*0.5); c.lineTo(-r*0.8, -r*0.8); c.fill();
        c.beginPath(); c.moveTo(r*0.8,0); c.lineTo(r*1.8, -r*0.5); c.lineTo(r*0.8, -r*0.8); c.fill();
        // Ears
        c.beginPath(); c.moveTo(-r*0.3, -r*0.6); c.lineTo(-r*0.4, -r*1.1); c.lineTo(0, -r*0.8); c.fill();
        c.beginPath(); c.moveTo(r*0.3, -r*0.6); c.lineTo(r*0.4, -r*1.1); c.lineTo(0, -r*0.8); c.fill();
        // Shades
        c.fillStyle = "#000"; c.fillRect(-r*0.5, -r*0.2, r, r*0.3);
    } 
    else if (id === "inferno") {
        // DRAGON (Horns)
        c.fillStyle = "#d84315"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Snout
        c.fillStyle = "#bf360c"; c.beginPath(); c.ellipse(0, r*0.3, r*0.4, r*0.3, 0, 0, Math.PI*2); c.fill();
        // Horns
        c.fillStyle = "#ffeb3b"; c.beginPath(); c.moveTo(-r*0.3, -r*0.7); c.lineTo(-r*0.5, -r*1.3); c.lineTo(-r*0.1, -r*0.9); c.fill();
        c.beginPath(); c.moveTo(r*0.3, -r*0.7); c.lineTo(r*0.5, -r*1.3); c.lineTo(r*0.1, -r*0.9); c.fill();
    } 
    else if (id === "glacial") {
        // PENGUIN (Beanie)
        c.fillStyle = "#29b6f6"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // White Face
        c.fillStyle = "#fff"; c.beginPath(); c.ellipse(0, 0, r*0.8, r*0.7, 0, 0, Math.PI*2); c.fill();
        // Beak
        c.fillStyle = "#ff9800"; c.beginPath(); c.moveTo(-r*0.15, 0); c.lineTo(r*0.15, 0); c.lineTo(0, r*0.3); c.fill();
        // Beanie
        c.fillStyle = "#d32f2f"; c.beginPath(); c.arc(0, -r*0.8, r*0.5, Math.PI, 0); c.fill();
        c.fillStyle = "#fff"; c.beginPath(); c.arc(0, -r*1.4, r*0.2, 0, Math.PI*2); c.fill();
    } 
    else if (id === "holy") {
        // CHICKEN (Halo)
        c.fillStyle = "#fff"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Comb
        c.fillStyle = "#d32f2f"; c.beginPath(); c.arc(0, -r*0.9, r*0.25, 0, Math.PI*2); c.fill();
        // Beak
        c.fillStyle = "#ffeb3b"; c.beginPath(); c.moveTo(0,0); c.lineTo(-r*0.2, r*0.4); c.lineTo(r*0.2, r*0.4); c.fill();
        // Halo
        c.strokeStyle = "#ffd700"; c.lineWidth = 3; c.beginPath(); c.ellipse(0, -r*0.4, r*0.3, r*0.1, 0, 0, Math.PI*2); c.stroke();
    } 
    else if (id === "shadow") {
        // RACCOON (Bandit)
        c.fillStyle = "#9e9e9e"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Mask
        c.fillStyle = "#424242"; c.fillRect(-r*0.7, -r*0.3, r*1.4, r*0.4);
        // Ears
        c.fillStyle = "#9e9e9e"; c.beginPath(); c.moveTo(-r*0.6, -r*0.6); c.lineTo(-r*0.8, -r*1.1); c.lineTo(-r*0.3, -r*0.8); c.fill();
        c.beginPath(); c.moveTo(r*0.6, -r*0.6); c.lineTo(r*0.8, -r*1.1); c.lineTo(r*0.3, -r*0.8); c.fill();
        // Bandana
        c.fillStyle = "#d32f2f"; c.beginPath(); c.moveTo(0, r*0.5); c.lineTo(-r, r); c.lineTo(0, r*0.8); c.lineTo(r, r); c.fill();
    } 
    else if (id === "mecha") {
        // ROBO-DOG
        c.fillStyle = "#78909c"; c.fillRect(-r*0.7, -r*0.8, r*1.4, r*1.6); // Box Head
        // Ears
        c.fillStyle = "#546e7a"; c.beginPath(); c.moveTo(-r*0.7, -r*0.8); c.lineTo(-r*0.9, -r*0.4); c.lineTo(-r*0.5, -r*0.4); c.fill();
        c.beginPath(); c.moveTo(r*0.7, -r*0.8); c.lineTo(r*0.9, -r*0.4); c.lineTo(r*0.5, -r*0.4); c.fill();
        // Eyes
        c.fillStyle = "#00e676"; c.fillRect(-r*0.5, -r*0.4, r*0.3, r*0.3); c.fillRect(r*0.2, -r*0.4, r*0.3, r*0.3);
    } 
    else if (id === "cosmic") {
        // SPACE CAT
        c.fillStyle = "#3f51b5"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
        // Ears
        c.beginPath(); c.moveTo(-r*0.6, -r*0.6); c.lineTo(-r*0.7, -r*1.3); c.lineTo(-r*0.2, -r*0.8); c.fill();
        c.beginPath(); c.moveTo(r*0.6, -r*0.6); c.lineTo(r*0.7, -r*1.3); c.lineTo(r*0.2, -r*0.8); c.fill();
        // Astronaut Helmet Glow
        c.strokeStyle = "#82b1ff"; c.lineWidth = 2; c.beginPath(); c.arc(0,0,r*1.2,0,Math.PI*2); c.stroke();
    } 
    else {
        // Default
        c.fillStyle = color || "#fff"; c.beginPath(); c.arc(0,0,r,0,Math.PI*2); c.fill();
    }
    
    // DIRECTION ARROW
    c.fillStyle="rgba(255,255,255,0.7)"; 
    c.beginPath(); c.moveTo(r*1.3, 0); c.lineTo(r*0.9, -r*0.3); c.lineTo(r*0.9, r*0.3); c.fill();

    c.restore();
}

function drawProjectiles() {
    if(!gameState.projectiles) return;
    gameState.projectiles.forEach(p => {
        let sx=p.start_pos.x, sy=p.start_pos.y;
        if(gameState.entities[p.from_id]) { sx=gameState.entities[p.from_id].pos.x; sy=gameState.entities[p.from_id].pos.y; }
        ctx.strokeStyle="#88ccff"; ctx.lineWidth=3; ctx.beginPath(); ctx.moveTo(sx,sy); ctx.lineTo(p.pos.x,p.pos.y); ctx.stroke();
        ctx.save(); ctx.translate(p.pos.x,p.pos.y); ctx.rotate(p.rotation);
        ctx.fillStyle="#e0f0ff"; ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(-12,-8); ctx.lineTo(10,0); ctx.lineTo(-12,8); ctx.fill(); ctx.restore();
    });
}
// ... (drawUnits cleanup)
// Ensure updateHUD runs!
setInterval(updateHUD, 100);

function drawAnimations() {
    ctx.fillStyle="#d50000"; for(let i=particles.length-1;i>=0;i--) { let p=particles[i]; p.x+=p.vx; p.y+=p.vy; p.life-=0.05; ctx.globalAlpha=p.life; ctx.beginPath(); ctx.arc(p.x,p.y,3,0,Math.PI*2); ctx.fill(); if(p.life<=0) particles.splice(i,1); } ctx.globalAlpha=1;
}
