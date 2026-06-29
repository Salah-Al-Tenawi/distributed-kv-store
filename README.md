# Distributed Key-Value Store

A distributed key-value store built on the core ideas of the **Raft** consensus
protocol. The system runs as a cluster of 5 nodes and ships with a live web
dashboard for controlling and observing the cluster in real time.

This project was built for a Distributed Systems course to demonstrate how the
main concepts of distributed systems work together in a single, runnable system.

## Implemented Concepts

| Concept | Description |
| --- | --- |
| Leader Election | A single leader is elected with randomized timeouts and majority voting. |
| Heartbeats & Failure Detection | The leader sends periodic heartbeats; unreachable nodes are marked offline. |
| Log / Data Replication | Writes are appended to a replicated log and applied once committed by a majority. |
| Fault Tolerance & Network Partition | The cluster survives node crashes and network splits (split-brain protection). |
| Distributed Locks | Mutual exclusion with TTL leases and monotonic fencing tokens. |
| Two-Phase Commit (2PC) | Atomic transactions across nodes — commit only if every node agrees. |
| Vector Clocks | Causality tracking to distinguish ordered events from concurrent ones. |
| Consistent Hashing / Sharding | Keys are distributed over a hash ring with minimal remapping on membership change. |

## Architecture

```
        ┌──────────────────────────────┐
        │      Flutter Web Dashboard    │   control + live monitoring
        └───────────────┬──────────────┘
                        │  WebSocket (state) + HTTP (commands)
        ┌───────────────┴──────────────┐
        │      Aggregator Gateway       │   single public service
        └───────────────┬──────────────┘
        ┌───────────────┴──────────────┐
        │   Cluster of 5 nodes (Node.js)│   node-1 .. node-5
        └──────────────────────────────┘
```

- **Backend** — Node.js (Express + ws). Five nodes communicate over RPC and
  expose an HTTP + WebSocket interface each.
- **Frontend** — Flutter Web, structured with Clean Architecture and the Cubit
  (BLoC) state management pattern.
- **Gateway** — bundles the cluster and serves the web UI behind a single port,
  so the whole project can be deployed (or tunneled) as one service.

## Getting Started

Requirements: Node.js 20+ and Flutter 3+.

Run the backend cluster (terminal 1):

```bash
cd backend
npm install
npm run cluster
```

Run the web dashboard (terminal 2):

```bash
flutter pub get
flutter run -d chrome
```

## Running as a Single Service

Build the web UI in gateway mode, copy it into the backend, and start the gateway:

```bash
flutter build web --dart-define=GATEWAY=true
cp -r build/web/* backend/public/
cd backend && npm start
```

The app is then available at `http://localhost:8080`. To expose a temporary
public link (for a quick demo), run `share.bat`, which starts the gateway and
opens a Cloudflare Tunnel.

## Project Structure

```
backend/
  src/
    index.js            entry point for a single node
    gateway.js          single-service gateway (cluster + web + proxy)
    config.js           cluster nodes and timing settings
    node/               election, replication, twoPhaseCommit, vectorClock
    transport/          peerRpc, dashboard, clientApi, lockApi, txnApi, vcApi, admin
    store/kvStore.js    replicated state machine
  public/               built Flutter web (served by the gateway)
lib/
  core/                 network, dependency injection, utilities, constants
  features/cluster/     data / domain / presentation (Cubit + widgets)
```
