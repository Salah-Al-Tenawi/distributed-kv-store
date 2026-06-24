/// حلقة التجزئة المتّسقة (Consistent Hash Ring).
///
/// توضع كل عقدة على الحلقة في عدّة مواضع افتراضية (Virtual Nodes / replicas)
/// لتوزيع أعدل. يُسنَد المفتاح للعقدة عند أول موضع على الحلقة ≥ تجزئة المفتاح
/// (باتجاه عقارب الساعة)، ومع تجاوز النهاية نلتفّ للبداية.
///
/// الميزة: عند إضافة/إزالة عقدة، تنتقل فقط المفاتيح المجاورة لها على الحلقة
/// (≈ 1/N من المفاتيح) بدل إعادة توزيع الكل (كما في hash % N).
class ConsistentHashRing {
  final int virtualNodes;
  final List<int> _ring = []; // مواضع مرتّبة على الحلقة
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

  /// تُرجع معرّف العقدة المالكة للمفتاح، أو null إن كانت الحلقة فارغة.
  String? owner(String key) {
    if (_ring.isEmpty) return null;
    final h = _hash(key);
    // بحث ثنائي عن أول موضع ≥ h.
    var lo = 0, hi = _ring.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_ring[mid] < h) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final pos = lo == _ring.length ? _ring.first : _ring[lo]; // التفاف
    return _hashToNode[pos];
  }

  /// تجزئة FNV-1a بطول 32 بت — ثابتة (deterministic) عبر التشغيلات.
  static int _hash(String s) {
    var hash = 0x811c9dc5;
    for (final c in s.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
