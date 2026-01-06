1. Tech Stack (Công nghệ sử dụng)
   Chúng ta sẽ giữ nguyên Backend (Go) vì nó đang làm tốt việc xử lý logic và chịu tải, chỉ thay thế Frontend.

Backend (Server):

Language: Go (Golang).

Architecture: Authoritative Server (Server tính toán tất cả vật lý, va chạm, máu).

Communication: WebSocket (Gói tin JSON).

Deployment: Docker + Nginx (Reverse Proxy & SSL).

Frontend (Client - Mới):

Language: JavaScript (ES6+).

Rendering: HTML5 Canvas API (Vẽ 2D thuần túy, hiệu năng cao, không cần Engine nặng).

Framework (Optional): Không dùng Engine (như Unity/Godot). Có thể dùng PixiJS nếu muốn vẽ đẹp và nhàn hơn, hoặc Canvas thuần để code gọn nhẹ nhất (khuyên dùng Canvas thuần cho dự án học tập/IO đơn giản).

Logic: Client-side Prediction (Dự đoán di chuyển) + Interpolation (Nội suy vị trí server) để mượt mà.

2. Game Logic (Cơ chế Game)
   Dựa trên code backend Golang bạn đã có, logic cốt lõi sẽ như sau:

A. Bản đồ & Môi trường
Kích thước: 1600x900 (Tỉ lệ 16:9).

Vùng an toàn: Sân nhà 2 bên.

Sông (The River): Nằm giữa bản đồ.

Là vùng "Tử địa" hoặc chướng ngại vật.

Không thể đi bộ xuống sông (bị chặn bởi tường vô hình).

Chỉ có thể bị Kéo (Hook) qua sông.

Trụ/Tường: Các vật cản chặn đường đạn hoặc di chuyển.

B. Nhân vật (Hero)
Di chuyển:

Cơ chế: RTS / MOBA Style (Chuột phải để đi).

Client gửi tọa độ đích (Target X, Y) -> Server tính toán Velocity và di chuyển nhân vật.

Chỉ số: Máu (HP), Mana (MP), Tốc độ chạy.

C. Kỹ năng (Skills) - Bộ 2 Skill Pudge
Skill Q: The Hook (Kéo)

Loại: Projectile (Đạn bay thẳng).

Tác dụng:

Bắn ra một cái móc theo hướng chỉ định.

Nếu trúng địch: Gây sát thương + Kéo địch về vị trí người kéo (Băng qua sông/tường).

Nếu trúng tường: Móc bị thu về (hoặc kéo người tới tường - tùy logic backend).

Skill W: Rot (Dịch hạch)

Loại: Toggle (Bật/Tắt).

Tác dụng:

Khi Bật: Gây sát thương liên tục (Damage over Time) ra xung quanh bản thân (bán kính 50-100px).

Cái giá: Tự gây sát thương lên chính mình (Self-damage) nhưng ít hơn gây cho địch.

3. Planning (Kế hoạch triển khai lại Frontend)
   Chúng ta sẽ chia làm 5 giai đoạn nhỏ để code tới đâu chắc tới đó.

Phase 1: Setup & Connection (Hôm nay)
Tạo file index.html, style.css, game.js.

Thiết lập Canvas full màn hình, tự resize.

Viết class NetworkManager trong JS để kết nối WebSocket tới Server Go (ws://localhost:8080/ws hoặc wss://hook.firstdraft.sh/ws).

Mục tiêu: Console log hiện "Connected" và nhận được packet room_joined.

Phase 2: Rendering Loop & Input
Viết vòng lặp game (requestAnimationFrame).

Vẽ bản đồ cơ bản (Nền xanh, Sông xanh dương, Grid).

Bắt sự kiện Chuột phải (Right Click) -> Gửi packet input dạng move lên server.

Bắt sự kiện Phím (Q, W) -> Gửi packet input dạng skill.

Phase 3: Entity Management
Xử lý packet game_update từ Server (chứa danh sách entities).

Vẽ nhân vật (Hình tròn đơn giản trước) tại đúng tọa độ Server trả về.

Áp dụng Interpolation (Nội suy): Giúp nhân vật di chuyển mượt mà giữa các lần cập nhật của Server (tránh bị giật cục).

Phase 4: Visual Polish (Làm đẹp)
Thay hình tròn bằng Sprite (Hình ảnh nhân vật).

Vẽ hiệu ứng Hook (Dây xích, Đầu móc).

Vẽ hiệu ứng Rot (Vòng tròn khí độc mờ ảo).

Thêm thanh máu (HP Bar), tên người chơi.

Phase 5: UI & Meta
Màn hình Login / Nhập tên.

Màn hình Lobby (Tạo phòng/Vào phòng).

Màn hình Game Over (Thắng/Thua).
