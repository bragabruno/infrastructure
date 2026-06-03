#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP=${KAFKA_BOOTSTRAP_SERVERS:-kafka:29092}
PARTITIONS=${KAFKA_PARTITIONS:-1}
REPLICATION=${KAFKA_REPLICATION_FACTOR:-1}

TOPICS=(
  "transactions.created"
  "fraud.scored"
  "fraud.review.required"
  "fraud.confirmed"
  "fraud.falsepositive"
  "fraud.retraining.requested"
  "fraud.model.deployed"
)

log() { echo "[kafka-init] $*"; }

log "Waiting for Kafka at $BOOTSTRAP..."
for i in $(seq 1 30); do
  if kafka-broker-api-versions --bootstrap-server "$BOOTSTRAP" &>/dev/null; then
    log "Kafka is ready"
    break
  fi
  [[ $i -eq 30 ]] && { log "ERROR: Kafka not ready after 60s"; exit 1; }
  sleep 2
done

log "Creating ${#TOPICS[@]} topics (partitions=$PARTITIONS, replication=$REPLICATION)..."
for topic in "${TOPICS[@]}"; do
  if kafka-topics --bootstrap-server "$BOOTSTRAP" --describe --topic "$topic" &>/dev/null; then
    log "  $topic (already exists)"
  else
    kafka-topics --bootstrap-server "$BOOTSTRAP" \
      --create --if-not-exists \
      --topic "$topic" \
      --partitions "$PARTITIONS" \
      --replication-factor "$REPLICATION"
    log "  $topic (created)"
  fi
done

log "All topics ready."
kafka-topics --bootstrap-server "$BOOTSTRAP" --list
