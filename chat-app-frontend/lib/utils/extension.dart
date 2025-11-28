
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  String withHostUrl() {
    if (startsWith('http')) {
      return this;
    }
    return Uri.base.origin + this;
  }

}