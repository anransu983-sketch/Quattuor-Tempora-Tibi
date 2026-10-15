import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dream_home_prefs.dart';
import 'dream_home_settings.dart';
import 'dream_sidebar.dart';
import 'widgets/dream_orb.dart';

class DreamHomeView extends ConsumerStatefulWidget {
  const DreamHomeView({super.key});

  @override
  ConsumerState<DreamHomeView> createState() => _DreamHomeViewState();
}

class _DreamHomeViewState extends ConsumerState<DreamHomeView> {
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    await ref.read(dreamGreetingProvider.notifier).load();
    if (!mounted) {
      return;
    }
    await ref.read(dreamSidebarExpandedProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DreamSidebar(),
        Expanded(
          child: SafeArea(
            left: false,
            child: Container(
              color: context.colorScheme.surface,
              padding: const EdgeInsets.all(12),
              child: const _DreamMainCard(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DreamMainCard extends StatelessWidget {
  const _DreamMainCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: AppShape.xxl,
        color: context.colorScheme.surfaceContainerLowest,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Expanded(flex: 5, child: _OrbArea()),
          const _TrafficRow(),
          const SizedBox(height: 8),
          const _NodeRow(),
          const SizedBox(height: 12),
          const _GreetingBlock(),
          const SizedBox(height: 16),
          const _BottomBar(),
          SizedBox(height: 16 + BottomInsetScope.of(context)),
        ],
      ),
    );
  }
}

class _OrbArea extends StatelessWidget {
  const _OrbArea();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter =
            (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight) *
                0.86;
        return Center(child: DreamOrb(diameter: diameter));
      },
    );
  }
}

class _TrafficRow extends ConsumerWidget {
  const _TrafficRow();

  Widget _trafficCell(TrafficShow show, String label, TextStyle? valueStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        Text(show.value, style: valueStyle),
        const SizedBox(width: 3),
        Text(
          show.unit,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffic = ref.watch(trafficsProvider).list.safeLast(const Traffic());
    final valueStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: context.colorScheme.onSurface,
      height: 1.0,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _trafficCell(traffic.up.traffic, 'UP', valueStyle),
        _trafficCell(traffic.down.traffic, 'DOWN', valueStyle),
      ],
    );
  }
}

class _NodeRow extends ConsumerWidget {
  const _NodeRow();

  void _testCurrentNode(WidgetRef ref) {
    final groups = ref.read(visibleGroupsStateProvider).value;
    if (groups.isEmpty) {
      return;
    }
    final group = groups.first;
    final nodeName = ref.read(selectedProxyNameProvider(group.name));
    if (nodeName == null || nodeName.isEmpty) {
      return;
    }
    Proxy? target;
    for (final proxy in group.all) {
      if (proxy.name == nodeName) {
        target = proxy;
        break;
      }
    }
    if (target != null) {
      ref.read(proxiesActionProvider.notifier).proxyDelayTest(target);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(visibleGroupsStateProvider).value;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }
    final group = groups.first;
    final nodeName = ref.watch(selectedProxyNameProvider(group.name)) ?? '';
    final delay = ref.watch(
      delayProvider(proxyName: nodeName, testUrl: group.testUrl),
    );
    final testing =
        ref.watch(
          delayTestPhaseProvider(proxyName: nodeName, testUrl: group.testUrl),
        ) !=
        null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: testing ? null : () => _testCurrentNode(ref),
      child: Row(
        children: [
          Expanded(
            child: EmojiText(
              nodeName.isEmpty ? '—' : nodeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          if (testing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            _DelayLabel(delay: delay),
        ],
      ),
    );
  }
}

class _DelayLabel extends StatelessWidget {
  const _DelayLabel({required this.delay});

  final int? delay;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final text = _label(appLocalizations);
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.colorScheme.delayColor(delay),
      ),
    );
  }

  String _label(AppLocalizations appLocalizations) {
    final value = delay;
    if (value == null) {
      return '--';
    }
    if (value > 0) {
      return '$value ms';
    }
    return delayFailureText(value, appLocalizations);
  }
}

class _GreetingBlock extends ConsumerWidget {
  const _GreetingBlock();

  String _timeGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.dreamGreetingMorning;
    }
    if (hour < 18) {
      return l10n.dreamGreetingAfternoon;
    }
    return l10n.dreamGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final customGreeting = ref.watch(dreamGreetingProvider);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _timeGreeting(appLocalizations),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (customGreeting.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              customGreeting,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final isStart = ref.watch(isStartProvider);
    return Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              showSheet(
                context: context,
                builder: (_) => const DreamHomeSettingsSheet(),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: AppShape.circle,
              padding: EdgeInsets.zero,
            ),
            child: GlyphIcon(
              AppGlyphs.settings,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                ref.read(commonActionProvider.notifier).toggleRunning();
              },
              child: Text(
                isStart ? appLocalizations.dreamStop : appLocalizations.start,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
