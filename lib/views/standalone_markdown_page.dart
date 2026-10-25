import 'dart:io';
import 'package:flutter/material.dart';
import 'package:solducci/widgets/liquid_markdown_editor.dart';
import 'package:solducci/service/recent_markdown_service.dart';
import 'package:solducci/service/markdown_inbox_service.dart';
import 'package:solducci/service/markdown_settings_service.dart';
import 'package:solducci/widgets/markdown_viewer_settings_sheet.dart';

class StandaloneMarkdownPage extends StatefulWidget {
  final String filePath;

  const StandaloneMarkdownPage({super.key, required this.filePath});

  @override
  State<StandaloneMarkdownPage> createState() => _StandaloneMarkdownPageState();
}

class _StandaloneMarkdownPageState extends State<StandaloneMarkdownPage> {
  String _content = '';
  String _fileName = '';
  bool _isLoading = true;
  String _error = '';
  final _settingsService = MarkdownSettingsService();

  @override
  void initState() {
    super.initState();
    _settingsService.init();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        _content = await file.readAsString();
        _fileName = widget.filePath.split(Platform.pathSeparator).last;
        
        // Track recent file & register in Markdown Inbox
        await RecentMarkdownService().addFile(widget.filePath, _fileName);
        await MarkdownInboxService().registerFile(widget.filePath, _fileName, _content);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Il file non esiste più in questo percorso.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Errore durante la lettura del file: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveFile(String newContent) async {
    try {
      final file = File(widget.filePath);
      await file.writeAsString(newContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Errore Lettura', style: TextStyle(color: Colors.white)),
        ),
        body: Center(child: Text(_error, style: const TextStyle(color: Colors.red))),
      );
    }

    return AnimatedBuilder(
      animation: _settingsService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _fileName,
              style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                tooltip: 'Impostazioni Visualizzatore',
                onPressed: () => MarkdownViewerSettingsSheet.show(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LiquidMarkdownEditor(
                initialText: _content,
                initialTitle: _fileName.replaceAll('.md', ''),
                autoOpenEditor: false,
                defaultExpanded: _settingsService.defaultExpanded,
                markdownFontSize: _settingsService.fontSize,
                readOnlyLock: _settingsService.readOnlyLock,
                maxWidth: MediaQuery.of(context).size.width - 32,
                onTextChanged: (newText) {
                  _content = newText;
                },
                onSave: () {
                  _saveFile(_content);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
