
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  String withHostUrl() {
    return Uri.base.origin + this;
  }

}