import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/dream/panel_prefs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panel_view.dart';

class PanelHomeView extends ConsumerStatefulWidget {
  const PanelHomeView({super.key});

  @override
  ConsumerState<PanelHomeView> createState() => _PanelHomeViewState();
}

class _PanelHomeViewState extends ConsumerState<PanelHomeView> {
  final Map<DreamPanel, bool> _installed = {};
  DreamPanel? _downloading;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await ref.read(dreamPanelProvider.notifier).load();
    for (final panel in DreamPanel.values) {
      _installed[panel] = await PanelManager.isInstalled(panel);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _select(DreamPanel panel) async {
    ref.read(dreamPanelProvider.notifier).set(panel.value);
    ref.read(setupActionProvider.notifier).applyProfileDebounce();
  }

  Future<void> _download(DreamPanel panel) async {
    setState(() {
      _downloading = panel;
      _progress = 0;
    });
    try {
      await PanelManager.ensureInstalled(
        panel,
        onProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = received / total;
            });
          }
        },
      );
      _installed[panel] = true;
    } catch (e) {
      dialogs.showNotifier(e.toString(), level: MessageLevel.error);
    } finally {
      if (mounted) {
        setState(() {
          _downloading = null;
        });
      }
    }
  }

  Future<void> _openPanel() async {
    final panel = DreamPanel.fromValue(ref.read(dreamPanelProvider));
    if (_installed[panel] != true) {
      await _download(panel);
      if (_installed[panel] != true || !mounted) {
        return;
      }
      ref.read(setupActionProvider.notifier).applyProfileDebounce();
    }
    if (!mounted) {
      return;
    }
    unawaited(BaseNavigator.push(context, const PanelView()));
  }

  @override
  Widget build(BuildContext context) {
    final selected = DreamPanel.fromValue(ref.watch(dreamPanelProvider));
    final downloading = _downloading;
    return CommonScaffold(
      title: context.appLocalizations.dreamPanel,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: ShapeDecoration(
              shape: AppShape.lg,
              color: context.colorScheme.surfaceContainerLowest,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.appLocalizations.dreamPanelSelect,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selected.value,
                        icon: const GlyphIcon(AppGlyphs.chevronDown),
                        items: [
                          for (final panel in DreamPanel.values)
                            DropdownMenuItem(
                              value: panel.value,
                              child: Text(panel.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _select(DreamPanel.fromValue(value));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                for (final panel in DreamPanel.values)
                  _PanelStatusRow(
                    panel: panel,
                    installed: _installed[panel] ?? false,
                    isDownloading: downloading == panel,
                    progress: _progress,
                    onDownload: () => _download(panel),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: downloading == null ? _openPanel : null,
            child: Text(context.appLocalizations.dreamPanelOpen),
          ),
        ],
      ),
    );
  }
}

class _PanelStatusRow extends StatelessWidget {
  final DreamPanel panel;
  final bool installed;
  final bool isDownloading;
  final double progress;
  final VoidCallback onDownload;

  const _PanelStatusRow({
    required this.panel,
    required this.installed,
    required this.isDownloading,
    required this.progress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(panel.label),
                Text(
                  installed
                      ? appLocalizations.dreamPanelDownloaded
                      : isDownloading
                      ? appLocalizations.dreamPanelDownloading(
                          (progress * 100).toStringAsFixed(0),
                        )
                      : appLocalizations.dreamPanelNotDownloaded,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(value: progress),
                  ),
              ],
            ),
          ),
          if (!installed && !isDownloading)
            TextButton(onPressed: onDownload, child: Text(appLocalizations.dreamPanelDownload)),
        ],
      ),
    );
  }
}
