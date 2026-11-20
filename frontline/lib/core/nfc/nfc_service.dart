import 'dart:async';
import 'dart:io';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Screen 11 (Scan): "Inputs: QR; Barcode; NFC." No NDEF payload format
/// has been decided for OneMaanicare asset/space/inventory/vehicle tags,
/// so this reads the tag's raw hardware UID (present on every NFC tag
/// regardless of what, if anything, is written to it) and treats that
/// UID the same way a scanned QR/barcode value is treated - looked up
/// against the local Asset/Space/Inventory/Vehicle caches. If a real
/// NDEF content format is defined later, this is the place to read it
/// instead.
class NfcService {
  const NfcService._();

  static Future<bool> isAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  /// Starts a single-tag NFC session and resolves with the tag's UID as
  /// a hex string, or null if the session was stopped without a tag
  /// being read (e.g. the user backed out).
  static Future<String?> scanTagId() async {
    final completer = Completer<String?>();
    await NfcManager.instance.startSession(
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (tag) async {
        final id = _extractId(tag);
        await NfcManager.instance.stopSession();
        if (!completer.isCompleted) completer.complete(id);
      },
    );
    return completer.future;
  }

  static Future<void> cancel() => NfcManager.instance.stopSession();

  static String? _extractId(NfcTag tag) {
    if (Platform.isAndroid) {
      final bytes = NfcTagAndroid.from(tag)?.id;
      return bytes == null ? null : _toHex(bytes);
    }
    if (Platform.isIOS) {
      final mifare = MiFareIos.from(tag)?.identifier;
      if (mifare != null) return _toHex(mifare);
      final iso7816 = Iso7816Ios.from(tag)?.identifier;
      if (iso7816 != null) return _toHex(iso7816);
      final iso15693 = Iso15693Ios.from(tag)?.identifier;
      if (iso15693 != null) return _toHex(iso15693);
    }
    return null;
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
}
