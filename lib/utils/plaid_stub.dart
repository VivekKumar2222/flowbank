Future<void> openPlaidOnWeb({
  required String linkToken,
  required void Function(String publicToken) onSuccess,
  required void Function(String? errorCode, String? errorMessage) onExit,
}) async {
  throw UnsupportedError('openPlaidOnWeb is not supported on this platform');
}
