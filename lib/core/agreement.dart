/// 风险与隐私协议的共享常量。
class AppAgreement {
  AppAgreement._();

  /// 协议版本号：调整协议内容后递增，可让用户重新确认。
  static const String version = 'v1';

  /// 隐私政策 H5 地址。
  static const String privacyUrl =
      'https://doc-hosting.flycricket.io/coinaozx-fs/34c371e9-bca1-4fca-9748-42ebdfad5151/privacy';

  /// 隐私政策页面标题。
  static const String privacyTitle = 'Privacy Policy';

  /// 本地保存「已同意」状态的键。
  static String get acceptedKey => 'agreement_accepted_$version';
}
