/// 风险与隐私协议的共享常量。
class AppAgreement {
  AppAgreement._();

  /// 协议版本号：调整协议内容后递增，可让用户重新确认。
  static const String version = 'v1';

  /// 本地保存「已同意」状态的键。
  static String get acceptedKey => 'agreement_accepted_$version';
}
