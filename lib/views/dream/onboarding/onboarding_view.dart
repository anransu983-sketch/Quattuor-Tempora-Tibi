import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:material_ui/material_ui.dart';

const _kTeal = Color(0xFF149C87);
const _kTitleColor = Color(0xFF212121);
const _kSubtitleColor = Color(0xFF616161);
const _kPlaceholderColor = Color(0xFFE0E0E0);
const _kDotIdleColor = Color(0xFFBDBDBD);
const _kButtonColor = Color(0xFFF2F2F2);

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int pageCount) {
    if (_page >= pageCount - 1) {
      widget.onDone();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final titles = [
      appLocalizations.dreamOnboardingWelcome,
      appLocalizations.dreamOnboardingWallpaper,
      appLocalizations.dreamOnboardingSwipe,
      appLocalizations.dreamOnboardingSubscription,
    ];
    final subtitles = [
      appLocalizations.dreamOnboardingWelcomeSub,
      appLocalizations.dreamOnboardingWallpaperSub,
      appLocalizations.dreamOnboardingSwipeSub,
      appLocalizations.dreamOnboardingSubscriptionSub,
    ];
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.68,
            child: Container(
              decoration: ShapeDecoration(
                shape: AppShape.vertical(top: AppCorner.xxl),
                color: Colors.white,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        titles[_page],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: _kTitleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitles[_page],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _kSubtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 170,
                              height: 300,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: titles.length,
                                onPageChanged: (index) =>
                                    setState(() => _page = index),
                                itemBuilder: (context, index) =>
                                    _pageMock(index),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < titles.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 10,
                                height: 10,
                                decoration: ShapeDecoration(
                                  shape: AppShape.full,
                                  color: i == _page ? _kTeal : _kDotIdleColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 58,
                        child: TextButton(
                          style: const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              _kButtonColor,
                            ),
                            foregroundColor: WidgetStatePropertyAll(
                              _kTitleColor,
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(fontSize: 18),
                            ),
                          ),
                          onPressed: () => _onNext(titles.length),
                          child: Text(
                            _page == titles.length - 1 ? appLocalizations.dreamOnboardingStart : appLocalizations.dreamOnboardingNext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pageMock(int index) {
    return switch (index) {
      0 => _startMock(),
      1 => _wallpaperMock(),
      2 => _swipeMock(),
      _ => _subscribeMock(),
    };
  }

  Widget _phoneFrame({required Widget child}) {
    return Container(
      decoration: const ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Color(0xFFE3E3E3)),
        ),
        color: Color(0xFFF8F8F8),
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }

  Widget _block({
    double? width,
    double? height,
    double corner = AppCorner.sm,
    Color color = _kPlaceholderColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(shape: AppShape.all(corner), color: color),
    );
  }

  Widget _startMock() {
    return _phoneFrame(
      child: Column(
        children: [
          _block(width: double.infinity, height: 110, corner: AppCorner.lg),
          const SizedBox(height: 8),
          _block(width: double.infinity, height: 10),
          const SizedBox(height: 6),
          _block(width: 110, height: 10),
          const SizedBox(height: 6),
          _block(width: 80, height: 10),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 34,
              height: 34,
              decoration: const ShapeDecoration(
                shape: AppShape.full,
                color: _kTeal,
              ),
              child: const Center(
                child: Text(
                  '启',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wallpaperMock() {
    return _phoneFrame(
      child: Stack(
        children: [
          _block(
            width: double.infinity,
            height: double.infinity,
            corner: AppCorner.lg,
          ),
          Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: const ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: AppRadius.full,
                  side: BorderSide(color: _kTeal, width: 3.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeMock() {
    return _phoneFrame(
      child: Column(
        children: [
          Row(
            children: [
              _block(
                width: 52,
                height: 22,
                corner: AppCorner.full,
                color: _kTeal,
              ),
              const SizedBox(width: 6),
              _block(width: 34, height: 22, corner: AppCorner.full),
              const SizedBox(width: 6),
              _block(width: 34, height: 22, corner: AppCorner.full),
            ],
          ),
          const SizedBox(height: 8),
          _block(width: double.infinity, height: 60, corner: AppCorner.md),
          const SizedBox(height: 8),
          _block(
            width: double.infinity,
            height: 60,
            corner: AppCorner.md,
            color: const Color(0xFFDDEDEA),
          ),
          const SizedBox(height: 8),
          _block(width: double.infinity, height: 60, corner: AppCorner.md),
        ],
      ),
    );
  }

  Widget _subscribeMock() {
    return _phoneFrame(
      child: Stack(
        children: [
          Column(
            children: [
              Row(children: [_block(width: 64, height: 20), const Spacer()]),
              const SizedBox(height: 10),
              _block(width: double.infinity, height: 88, corner: AppCorner.md),
              const SizedBox(height: 8),
              _block(width: double.infinity, height: 88, corner: AppCorner.md),
              const Spacer(),
              _block(width: double.infinity, height: 34, corner: AppCorner.md),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const ShapeDecoration(
                shape: AppShape.full,
                color: _kTeal,
              ),
              child: const GlyphIcon(
                AppGlyphs.add,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
