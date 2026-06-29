function applyCommitted(node) {
  while (node.lastApplied < node.commitIndex) {
    node.lastApplied += 1;
    const entry = node.log[node.lastApplied];
    if (!entry) break;
    if (entry.op === 'SET') {
      node.kv[entry.key] = entry.value;
    } else if (entry.op === 'DEL') {
      delete node.kv[entry.key];
    } else if (entry.op === 'LOCK_ACQUIRE') {

      node.locks[entry.key] = {
        owner: entry.owner,
        token: entry.token,
        expiresAt: entry.expiresAt,
      };
    } else if (entry.op === 'LOCK_RELEASE') {

      const existing = node.locks[entry.key];
      node.locks[entry.key] = {
        owner: null,
        token: existing?.token ?? 0,
        expiresAt: 0,
      };
    }
    console.log(
      `[${node.id}] applied entry #${node.lastApplied}: ${entry.op} ${entry.key}` +
        (entry.op === 'SET' ? `=${entry.value}` : ''),
    );
  }
}

module.exports = { applyCommitted };
