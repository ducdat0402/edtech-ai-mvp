/// User-facing names for in-app coin currency (backend field remains `coins`).
abstract final class CurrencyLabels {
  CurrencyLabels._();

  /// Full name: cards, settings, tooltips
  static const String gtuCoin = 'GTU coin';

  /// Short suffix for inline rewards, e.g. +10 GTU
  static const String gtuShort = 'GTU';

  /// e.g. +42 GTU
  static String rewardShort(int amount) => '+$amount $gtuShort';

  /// e.g. 42 GTU coin
  static String balanceVerbose(int amount) => '$amount $gtuCoin';
}
