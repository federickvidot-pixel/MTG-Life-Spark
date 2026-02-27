import 'dart:io';

/// Returns the device's local WiFi/LAN IPv4 address, or null if unavailable.
///
/// Prefers WiFi interfaces (wlan*, en*); falls back to any non-loopback IPv4.
Future<String?> getLocalIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    // 1st pass: prefer known WiFi interface name prefixes
    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      if (name.startsWith('wlan') ||
          name.startsWith('wifi') ||
          name.startsWith('en') ||
          name.startsWith('eth')) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    }

    // 2nd pass: any non-loopback IPv4 (covers unusual interface names)
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
  } catch (_) {}
  return null;
}
