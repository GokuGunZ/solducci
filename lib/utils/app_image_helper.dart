import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solducci/widgets/common/avatar_crop_preview_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for avatar and image operations across Solducci.
///
/// Supports:
/// - Parsing both HTTP/HTTPS network URLs and base64 data URIs (MemoryImage)
/// - Picking images via FilePicker (works on mobile, web, and desktop)
/// - Interactive crop, zoom, pan, and preview before saving
/// - Automatic downscaling and compression to optimal avatar size (~280x280, <50KB)
/// - Uploading to Supabase Storage with graceful fallback to base64 data URI
/// - Modern modal sheet for choosing between gallery, web URL, or removing image
class AppImageHelper {
  /// Converts a URL string (HTTP/HTTPS or data:image/... base64 URI) to an [ImageProvider].
  /// Returns null if the URL is null or empty.
  static ImageProvider? getImageProvider(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('data:image') ||
        trimmed.startsWith('data:application') ||
        trimmed.startsWith('base64,')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64String =
            commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    }

    return NetworkImage(trimmed);
  }

  /// Displays the avatar picker sheet/dialog with preview & crop capabilities.
  /// Returns the new image URL (or data URI), '' to remove, or null if cancelled.
  static Future<String?> showAvatarPickerDialog(
    BuildContext context, {
    String title = 'Foto profilo',
    String? currentUrl,
  }) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final hasExisting = currentUrl != null && currentUrl.trim().isNotEmpty;

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF18181D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF27272A), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Option 1: Pick from Device
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Scegli dalla galleria o file',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Carica, ritaglia e ridimensiona un\'immagine',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(sheetContext, 'gallery'),
              ),
              const SizedBox(height: 8),
              // Option 2: Enter Web URL
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Inserisci URL web',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Usa un link diretto ad un\'immagine online',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(sheetContext, 'url'),
              ),
              if (hasExisting) ...[
                const SizedBox(height: 8),
                // Option 3: Remove
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Rimuovi immagine',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'remove'),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (!context.mounted) return null;

    if (action == 'gallery') {
      return await _pickAndProcessImage(context, title: title);
    } else if (action == 'url') {
      return await _showUrlInputDialog(context, title: title, currentUrl: currentUrl);
    } else if (action == 'remove') {
      return '';
    }
    return null;
  }

  /// Downscales image to square avatar size (default 280x280) so it's super lightweight (~30-60KB).
  static Future<Uint8List> _resizeAvatarImage(
    Uint8List inputBytes, {
    int targetDimension = 280,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        inputBytes,
        targetWidth: targetDimension,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error downscaling avatar image: $e');
    }
    return inputBytes;
  }

  /// Uploads processed image bytes to Supabase storage or converts to base64 data URI.
  static Future<String?> _saveAvatarBytes(Uint8List bytes, {String nameHint = 'avatar'}) async {
    // Ensure it's cleanly resized
    final processedBytes = await _resizeAvatarImage(bytes, targetDimension: 280);

    // Attempt Supabase storage upload first if bucket exists
    try {
      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = nameHint.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final remotePath = 'avatars/${timestamp}_$safeName.png';

      await supabase.storage.from('avatars').uploadBinary(
        remotePath,
        processedBytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(remotePath);
      if (publicUrl.isNotEmpty) {
        return publicUrl;
      }
    } catch (storageError) {
      debugPrint('Supabase storage upload bypassed/failed: $storageError. Using data URI fallback.');
    }

    // Fallback: direct base64 data URI with lightweight processed bytes
    final base64String = base64Encode(processedBytes);
    return 'data:image/png;base64,$base64String';
  }

  /// Picks an image file using FilePicker, launches the crop & preview dialog,
  /// and saves the resulting image to storage/data URI.
  static Future<String?> _pickAndProcessImage(
    BuildContext context, {
    String title = 'Ritaglia foto profilo',
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.single;
      Uint8List? rawBytes = file.bytes;
      final filePath = file.path;

      if (rawBytes == null && filePath != null && !kIsWeb) {
        final localFile = File(filePath);
        if (localFile.existsSync()) {
          rawBytes = localFile.readAsBytesSync();
        }
      }

      if (rawBytes == null || rawBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossibile leggere il file selezionato')),
          );
        }
        return null;
      }

      if (!context.mounted) return null;

      // Launch Interactive Crop & Preview modal
      final croppedBytes = await AvatarCropPreviewDialog.show(
        context,
        imageBytes: rawBytes,
        title: title,
      );

      if (croppedBytes == null) {
        // User cancelled crop
        return null;
      }

      return await _saveAvatarBytes(croppedBytes, nameHint: file.name);
    } catch (e) {
      debugPrint('Error picking avatar image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la selezione: $e')),
        );
      }
      return null;
    }
  }

  /// Dialog to enter an image URL directly with crop & preview support
  static Future<String?> _showUrlInputDialog(
    BuildContext context, {
    String title = 'Ritaglia foto',
    String? currentUrl,
  }) async {
    final controller = TextEditingController(text: currentUrl ?? '');

    final url = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18181D),
        title: const Text(
          'Inserisci URL immagine',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incolla il link diretto all\'immagine (JPG, PNG, WebP):',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, null),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogCtx, text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Avanti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (url == null || url.trim().isEmpty || !context.mounted) {
      return null;
    }

    // Try downloading the URL to allow the user to crop & preview it!
    try {
      final response = await http.get(Uri.parse(url.trim())).timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty && context.mounted) {
        final croppedBytes = await AvatarCropPreviewDialog.show(
          context,
          imageBytes: response.bodyBytes,
          title: title,
        );

        if (croppedBytes != null) {
          return await _saveAvatarBytes(croppedBytes, nameHint: 'url_avatar');
        }
        return null;
      }
    } catch (e) {
      debugPrint('Could not download image from URL for cropping ($e), fallback to raw URL');
    }

    // If download/crop failed or was bypassed, return raw URL
    return url.trim();
  }
}
