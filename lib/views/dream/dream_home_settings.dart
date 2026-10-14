import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dream_home_prefs.dart';

class DreamHomeSettingsSheet extends ConsumerStatefulWidget {
  const DreamHomeSettingsSheet({super.key});

  @override
  ConsumerState<DreamHomeSettingsSheet> createState() =>
      _DreamHomeSettingsSheetState();
}

class _DreamHomeSettingsSheetState
    extends ConsumerState<DreamHomeSettingsSheet> {
  late final TextEditingController _greetingController;

  @override
  void initState() {
    super.initState();
    _greetingController = TextEditingController(
      text: ref.read(dreamGreetingProvider),
    );
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final sidebarExpanded = ref.watch(dreamSidebarExpandedProvider);
    return CommonScaffold(
      title: appLocalizations.dreamHomeSettings,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            appLocalizations.dreamCustomGreeting,
            style: TextStyle(
              fontSize: 13,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _greetingController,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: appLocalizations.dreamCustomGreeting,
              counterText: '',
            ),
            onChanged: (value) {
              ref.read(dreamGreetingProvider.notifier).set(value);
            },
          ),
          const SizedBox(height: 16),
          Container(
            decoration: ShapeDecoration(
              shape: AppShape.lg,
              color: context.colorScheme.surfaceContainerLowest,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    appLocalizations.dreamExpandSidebar,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Switch(
                  value: sidebarExpanded,
                  onChanged: (value) {
                    ref.read(dreamSidebarExpandedProvider.notifier).set(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
