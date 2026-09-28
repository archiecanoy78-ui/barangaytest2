// Allows redirecting the browser on web builds.
// This file is only used when compiling to web (dart:html available).
import 'dart:html' as html;

void redirectTo(String url) {
  html.window.location.href = url;
}
