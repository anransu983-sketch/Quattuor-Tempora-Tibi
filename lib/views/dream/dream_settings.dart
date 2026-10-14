import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/backup_and_restore.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/rules.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dream_home_settings.dart';

class DreamSettingsView extends ConsumerWidget {
  const DreamSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        _SectionHeader(label: appLocalizations.dreamSectionInterface),
        _HubCard(
          children: [
            _HubRow(
              glyph: AppGlyphs.settings,
              title: appLocalizations.dreamAppSettings,
              subtitle: appLocalizations.dreamAppSettingsSub,
              onTap: () {
                BaseNavigator.push(context, const GeneralView());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.wifi,
              title: appLocalizations.dreamNetworkSettings,
              subtitle: appLocalizations.dreamNetworkSettingsSub,
              onTap: () {
                BaseNavigator.push(context, const NetworkListView());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.code,
              title: appLocalizations.dreamOverrideSettings,
              subtitle: appLocalizations.dreamOverrideSettingsSub,
              onTap: () {
                BaseNavigator.push(context, const ScriptsView());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.home,
              title: appLocalizations.dreamHomeSettings,
              subtitle: appLocalizations.dreamHomeSettingsSub,
              onTap: () {
                showSheet(
                  context: context,
                  builder: (_) => const DreamHomeSettingsSheet(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(label: appLocalizations.dreamSectionMeta),
        _HubCard(
          children: [
            _HubRow(
              glyph: AppGlyphs.connections,
              title: appLocalizations.dreamConnections,
              onTap: () {
                BaseNavigator.push(context, const ConnectionsView());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.logs,
              title: appLocalizations.dreamLogs,
              onTap: () {
                BaseNavigator.push(context, const LogsView());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.rules,
              title: appLocalizations.dreamRules,
              onTap: () {
                BaseNavigator.push(context, const AddedRulesView());
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(label: appLocalizations.dreamSectionMore),
        _HubCard(
          children: [
            _HubRow(
              glyph: AppGlyphs.cloudDownload,
              title: appLocalizations.dreamBackup,
              subtitle: appLocalizations.dreamBackupSub,
              onTap: () {
                BaseNavigator.push(context, const BackupAndRestore());
              },
            ),
            _HubRow(
              glyph: AppGlyphs.info,
              title: appLocalizations.about,
              subtitle: appLocalizations.dreamAboutSub,
              onTap: () {
                BaseNavigator.push(context, const AboutView());
              },
            ),
          ],
        ),
      ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        separated.add(
          Divider(
            height: 1,
            indent: 56,
            color: context.colorScheme.outlineVariant,
          ),
        );
      }
      separated.add(children[i]);
    }
    return Container(
      decoration: ShapeDecoration(
        shape: AppShape.lg,
        color: context.colorScheme.surfaceContainerLowest,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: separated),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.glyph,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final Glyph glyph;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                shape: AppShape.md,
                color: context.colorScheme.primaryContainer,
              ),
              child: Center(
                child: GlyphIcon(
                  glyph,
                  color: context.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GlyphIcon(
              AppGlyphs.chevronForward,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
