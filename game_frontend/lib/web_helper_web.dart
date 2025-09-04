// Web implementation using dart:html
import 'dart:html' as html;

bool shouldResetData() {
  try {
    final url = html.window.location.href;
    return url.contains('reset_data=true');
  } catch (e) {
    return false;
  }
}

void clearWebStorage() {
  try {
    html.window.localStorage.clear();
  } catch (e) {
    // Ignore errors if localStorage is not available
  }
}

void cleanUpUrl() {
  try {
    final url = html.window.location.href;
    final cleanUrl = url.split('?')[0];
    html.window.history.replaceState(null, '', cleanUrl);
  } catch (e) {
    // Ignore errors if history API is not available
  }
}

void triggerAppReload() {
  try {
    // Reload the page to completely restart the Flutter app
    html.window.location.reload();
  } catch (e) {
    // Ignore errors if reload is not available
  }
}

void setResetFlag() {
  try {
    // Set a flag in localStorage to indicate reset happened
    html.window.localStorage['app_reset_flag'] = 'true';
  } catch (e) {
    // Ignore errors if localStorage is not available
  }
}