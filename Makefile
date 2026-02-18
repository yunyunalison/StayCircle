# StayCircle Makefile
# Helpful targets for local development and a production-like demo using Docker Compose.
# Common commands:
#   - make dev-up / dev-down / dev-logs
#   - make prod-up / prod-down / prod-logs
#   - make ps / make clean

.PHONY: dev-build dev-up dev-down dev-logs prod-build prod-up prod-down prod-logs ps clean

# Build images for the development stack
dev-build:
	docker compose -f docker-compose.dev.yml build

# Start the development stack (hot reload enabled)
dev-up:
	docker compose -f docker-compose.dev.yml up -d

# Stop the development stack
dev-down:
	docker compose -f docker-compose.dev.yml down

# Tail logs from the development stack
dev-logs:
	docker compose -f docker-compose.dev.yml logs -f --tail=200

# Build images for the production-like demo
prod-build:
	docker compose -f docker-compose.prod.yml build

# Start the production-like demo stack
prod-up:
	docker compose -f docker-compose.prod.yml up -d

# Stop the production-like demo stack
prod-down:
	docker compose -f docker-compose.prod.yml down

# Tail logs from the production-like demo stack
prod-logs:
	docker compose -f docker-compose.prod.yml logs -f --tail=200

# Show running containers (name, image, status, ports)
ps:
	docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

clean:
	# Remove dangling images/volumes (use with care; this prunes unused resources)
	docker image prune -f
	docker volume prune -f
