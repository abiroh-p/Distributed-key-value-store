# ── Makefile ─────────────────────────────────────────────────
PROTO_DIR   := proto
GEN_DIR     := gen/raft
BINARY_DIR  := bin

.PHONY: proto tidy build run-node1 run-node2 run-node3 run-cluster kill-cluster cli clean

## Generate protobuf + gRPC Go code from proto/raft.proto
proto:
	protoc \
		--go_out=$(GEN_DIR) --go_opt=paths=source_relative \
		--go-grpc_out=$(GEN_DIR) --go-grpc_opt=paths=source_relative \
		$(PROTO_DIR)/raft.proto

## Download / tidy dependencies
tidy:
	go mod tidy

## Build server binary
build:
	mkdir -p $(BINARY_DIR)
	go build -o $(BINARY_DIR)/dkvs-server ./cmd/server
	go build -o $(BINARY_DIR)/dkvs-cli    ./cmd/cli

## Run individual nodes
run-node1:
	./$(BINARY_DIR)/dkvs-server --config config/node1.yaml

run-node2:
	./$(BINARY_DIR)/dkvs-server --config config/node2.yaml

run-node3:
	./$(BINARY_DIR)/dkvs-server --config config/node3.yaml

## Start all 3 nodes in background
run-cluster: build
	./$(BINARY_DIR)/dkvs-server --config config/node1.yaml &
	./$(BINARY_DIR)/dkvs-server --config config/node2.yaml &
	./$(BINARY_DIR)/dkvs-server --config config/node3.yaml &
	@echo "Cluster started. Run 'make kill-cluster' to stop."

## Kill all running server processes
kill-cluster:
	@pkill -f "dkvs-server" && echo "Cluster stopped." || echo "No nodes running."

## Open interactive CLI
cli: build
	./$(BINARY_DIR)/dkvs-cli --addr :7000

## Remove build artifacts and data dirs
clean:
	rm -rf $(BINARY_DIR) data/
