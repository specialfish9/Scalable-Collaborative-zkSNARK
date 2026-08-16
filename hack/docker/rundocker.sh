#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------
IMAGE="hyperplonkpp-benchmarks"
DOCKERFILE="hack/docker/Dockerfile"

# Packing size l: the protocol requires exactly 8*l parties.
L=${1:-2}
# log2 of the circuit size.
M=${2:-10}
N=$((8*L))

NETWORK="worker-net"
SUBNET="172.30.0.0/24"

WORK_DIR="$(pwd)/shared"
LOG_DIR="$(pwd)/logs"
IPS_FILE="/tmp/ips.txt"

mkdir -p "$WORK_DIR" "$LOG_DIR"

PORT=10086

CONTAINER_PREFIX="worker"

echo "------------------------------"
echo "Configuration:"
echo "  L (packing size l) = $L"
echo "  M (log2 circuit) = $M"
echo "  N (workers, = 8*l) = $N"
echo "  Network = $NETWORK"
echo "  Subnet = $SUBNET"
echo "  Log dir = $LOG_DIR"
echo "------------------------------"

# -----------------------------
# Build image
# -----------------------------
echo "Building Docker image..."

TAG="$IMAGE:latest"
docker build -t $TAG -f $DOCKERFILE .

echo "Image built. Tag = $TAG"

# -----------------------------
# Create network
# -----------------------------
if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
    echo "Creating network $NETWORK"
    docker network create --subnet "$SUBNET" "$NETWORK"
fi

# -----------------------------
# Generate IP file
# -----------------------------
echo "Generating IP list..."

rm -f "$IPS_FILE"

for ((i=0; i<N; i++)); do
    ip="172.30.0.$((100+i))"
    echo "$ip:$PORT" >> "$IPS_FILE"
done

echo "Workers will use:"
cat "$IPS_FILE"

# -----------------------------
# Launch workers
# -----------------------------
echo "Launching $N workers..."

for ((i=0; i<N; i++)); do

(
    name="${CONTAINER_PREFIX}-${i}"

    entry=$(sed -n "$((i+1))p" "$IPS_FILE")
    ip="${entry%%:*}"

    echo "Starting $name ($ip)..."

    docker run \
        --rm \
        --name "$name" \
        --network "$NETWORK" \
        --ip "$ip" \
        -v "$IPS_FILE:/shared/ips.txt:ro" \
        "$IMAGE" \
        "$i" "$M" "$L" \
        > "$LOG_DIR/$name.log" 2>&1

    echo "$name completed"

) &

done


wait

echo "All workers completed."
