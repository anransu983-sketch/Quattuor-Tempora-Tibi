import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'onboarding_prefs.dart';
import 'onboarding_view.dart';

class OnboardingGate extends ConsumerStatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends ConsumerState<OnboardingGate> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ref.read(dreamOnboardingSeenProvider.notifier).load();
  }

  void _onDone() {
    ref.read(dreamOnboardingSeenProvider.notifier).markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final seen = ref.watch(dreamOnboardingSeenProvider);
    return Stack(
      children: [
        widget.child,
        if (!seen) Positioned.fill(child: OnboardingView(onDone: _onDone)),
      ],
    );
  }
}
