/// CEFR proficiency levels (A1–C2) for filtering podcasts by German level.
///
/// Phase 4 feature — modelled now so the [id] can be stored on podcasts from
/// the start (optional field), avoiding a later data migration. In Phase 1 this
/// is set manually by the creator (or left null); auto-estimation from a
/// transcript comes later.
enum CefrLevel {
  a1('a1', 'A1'),
  a2('a2', 'A2'),
  b1('b1', 'B1'),
  b2('b2', 'B2'),
  c1('c1', 'C1'),
  c2('c2', 'C2');

  const CefrLevel(this.id, this.label);

  final String id;
  final String label;

  static CefrLevel? fromId(String? id) {
    if (id == null) return null;
    for (final l in CefrLevel.values) {
      if (l.id == id) return l;
    }
    return null;
  }
}
