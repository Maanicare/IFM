/// Screen 37 (Permit to Work) types.
enum PermitType {
  hotWork,
  height,
  confinedSpace,
  electrical,
  excavation,
  lifting,
  other;

  String get label => switch (this) {
        PermitType.hotWork => 'Hot work',
        PermitType.height => 'Height',
        PermitType.confinedSpace => 'Confined space',
        PermitType.electrical => 'Electrical',
        PermitType.excavation => 'Excavation',
        PermitType.lifting => 'Lifting',
        PermitType.other => 'Other',
      };
}
