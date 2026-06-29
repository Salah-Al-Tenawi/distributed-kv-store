class ConsistentHashRing {
  final int virtualNodes;
  final List<int> _ring = [];
  final Map<int, String> _hashToNode = {};

  ConsistentHashRing(List<String> nodeIds, {this.virtualNodes = 80}) {
    for (final id in nodeIds) {
      for (var v = 0; v < virtualNodes; v++) {
        final h = _hash('$id#$v');
        _ring.add(h);
        _hashToNode[h] = id;
      }
    }
    _ring.sort();
  }

  bool get isEmpty => _ring.isEmpty;

  String? owner(String key) {
    if (_ring.isEmpty) return null;
    final h = _hash(key);

    var lo = 0, hi = _ring.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_ring[mid] < h) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final pos = lo == _ring.length ? _ring.first : _ring[lo];
    return _hashToNode[pos];
  }

  static int _hash(String s) {
    var hash = 0x811c9dc5;
    for (final c in s.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
