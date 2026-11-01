// lib/helpers/maps_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Opens the venue in a maps app. Falls back to Google Maps in the browser.
// No location permission is needed because we only send the venue coordinates.
Future<bool> openInMaps(GeoPoint geo) async {
  final geoUri = Uri.parse(
    'geo:${geo.latitude},${geo.longitude}?q=${geo.latitude},${geo.longitude}',
  );
  final webUri = Uri.parse(
    'https://maps.google.com/?q=${geo.latitude},${geo.longitude}',
  );

  try {
    final opened = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    if (opened) {
      return true;
    }
  } catch (_) {
    // No maps app installed, try the browser below.
  }

  return launchUrl(webUri, mode: LaunchMode.externalApplication);
}
