class AppConfig {
  // Existing production database is named "default", without parentheses.
  static const databaseId = String.fromEnvironment(
    'FIRESTORE_DATABASE_ID',
    defaultValue: 'default',
  );
}
