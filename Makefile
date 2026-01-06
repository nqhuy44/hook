.PHONY: dev backend frontend

# Default target
dev:
	@echo "Starting Backend (8080) and Frontend (3000)..."
	@trap 'kill 0' EXIT; \
	make backend & \
	make frontend & \
	wait

backend:
	@echo "Starting Go Backend..."
	go run main.go

frontend:
	@echo "Starting Web Frontend..."
	cd web && python3 -m http.server 3000
