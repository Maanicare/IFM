/// Screen 33 (Stock Transaction) types. `issue` isn't included here -
/// it stays the Work Order "Add part" flow's own type, recorded through
/// [PartsUsageController] instead of this one.
enum StockTransactionType {
  receive(wireValue: 'receive', isInbound: true),
  transfer(wireValue: 'transfer', isInbound: false),
  returned(wireValue: 'return', isInbound: true),
  repair(wireValue: 'repair', isInbound: false),
  scrap(wireValue: 'scrap', isInbound: false),
  adjustment(wireValue: 'adjustment', isInbound: true);

  const StockTransactionType({required this.wireValue, required this.isInbound});

  final String wireValue;

  /// Whether this type normally increases the balance. Ignored for
  /// [adjustment], where the entered quantity's own sign is used
  /// directly (a count correction can go either way).
  final bool isInbound;

  String get label => switch (this) {
        StockTransactionType.receive => 'Receive',
        StockTransactionType.transfer => 'Transfer',
        StockTransactionType.returned => 'Return',
        StockTransactionType.repair => 'Repair',
        StockTransactionType.scrap => 'Scrap',
        StockTransactionType.adjustment => 'Adjustment',
      };
}
