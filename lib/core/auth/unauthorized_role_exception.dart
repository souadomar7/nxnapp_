class UnauthorizedRoleException implements Exception {
  final String message;
  
  const UnauthorizedRoleException(this.message);

  @override
  String toString() => 'UnauthorizedRoleException: $message';
}
