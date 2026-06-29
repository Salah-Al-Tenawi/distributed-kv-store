function localEvent(node) {
  node.vectorClock[node.id] = (node.vectorClock[node.id] ?? 0) + 1;
}

function mergeClock(node, incoming) {
  for (const [id, val] of Object.entries(incoming || {})) {
    node.vectorClock[id] = Math.max(node.vectorClock[id] ?? 0, val);
  }
  node.vectorClock[node.id] = (node.vectorClock[node.id] ?? 0) + 1;
}

module.exports = { localEvent, mergeClock };
