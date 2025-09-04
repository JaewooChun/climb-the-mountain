// Stub implementation for non-web platforms

bool shouldResetData() {
  // On non-web platforms, never reset data via URL
  return false;
}

void clearWebStorage() {
  // No-op on non-web platforms
}

void cleanUpUrl() {
  // No-op on non-web platforms
}

void triggerAppReload() {
  // No-op on non-web platforms
}

void setResetFlag() {
  // No-op on non-web platforms
}