// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliumapp/config/app_route.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/config/pref_service.dart';
import 'package:heliumapp/presentation/core/views/base_page_screen_state.dart';
import 'package:heliumapp/presentation/ui/layout/responsive_center_card.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileWebScreen extends StatefulWidget {
  final String nextRoute;

  const MobileWebScreen({super.key, required this.nextRoute});

  @override
  State<MobileWebScreen> createState() => _MobileWebScreenState();
}

class _MobileWebScreenState extends BasePageScreenState<MobileWebScreen> {
  static const _cardMaxWidth = 350.0;
  static const _storeButtonHeight = 40.0;
  static const _featureIconSize = 18.0;
  static const _featureIconPadding = 7.0;
  static const _featureIconBorderRadius = 8.0;
  static const _featureIconSpacing = 10.0;
  static const _spinnerSize = 18.0;
  static const _spinnerStrokeWidth = 2.0;

  @override
  String get screenTitle => 'Get the Helium App';

  @override
  bool get isAuthenticatedScreen => false;

  bool _isOpeningStore = false;

  @override
  Widget buildScaffold(BuildContext context) {
    return Title(
      title: screenTitle,
      color: context.colorScheme.primary,
      child: Scaffold(body: SafeArea(child: buildMainArea(context))),
    );
  }

  @override
  Widget buildMainArea(BuildContext context) {
    return ResponsiveCenterCard(
      maxWidth: _cardMaxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_iphone_outlined,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.colorScheme.primary.withValues(alpha: 0.8),
                size: _featureIconSize,
              ),
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, color: context.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Get the Helium App',
            style: AppStyles.pageTitle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The native app is faster, smoother, and designed for your phone.',
            style: AppStyles.standardBodyText(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildFeatureItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Push notifications',
            description: 'Stay on top of everything with reminders.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            context,
            icon: Icons.touch_app_outlined,
            title: 'Better mobile UX',
            description: 'Designed for touch, gestures, and small screens.',
          ),
          const SizedBox(height: 10),
          _buildFeatureItem(
            context,
            icon: Icons.sync_outlined,
            title: 'Everything stays synced',
            description: 'Seamlessly transition between web, iOS, and Android.',
          ),
          const SizedBox(height: 18),
          ..._buildStoreButtonsForDetectedPlatform(),
          if (_isOpeningStore) ...[
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: _spinnerSize,
                height: _spinnerSize,
                child: const CircularProgressIndicator(strokeWidth: _spinnerStrokeWidth),
              ),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: _continueOnWeb,
            child: const Text('Continue on web'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStoreButtonsForDetectedPlatform() {
    final isIOS = Responsive.isIOSPlatform();
    final isAndroid = Responsive.isAndroidPlatform();

    final iosButton = _buildStoreButton(
      button: Buttons.apple,
      text: 'Download on the App Store',
      onPressed: () => _openStore(AppConstants.iosUrl),
    );
    final androidButton = _buildStoreButton(
      button: Buttons.googleDark,
      text: 'Get it on Google Play',
      onPressed: () => _openStore(AppConstants.androidUrl),
    );

    if (isIOS) return [iosButton];
    if (isAndroid) return [androidButton];
    return [iosButton, const SizedBox(height: 10), androidButton];
  }

  Widget _buildStoreButton({
    required Buttons button,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: _storeButtonHeight,
      child: IgnorePointer(
        ignoring: _isOpeningStore,
        child: Opacity(
          opacity: _isOpeningStore ? 0.5 : 1.0,
          child: SignInButton(button, text: text, onPressed: onPressed),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(_featureIconPadding),
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(_featureIconBorderRadius),
          ),
          child: Icon(icon, color: context.colorScheme.primary, size: _featureIconSize),
        ),
        const SizedBox(width: _featureIconSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.headingText(context)),
              Text(
                description,
                style: AppStyles.smallSecondaryText(context).copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openStore(String storeUrl) async {
    setState(() => _isOpeningStore = true);

    // Use _self to navigate current tab instead of opening new tab.
    // This allows iOS to properly intercept and redirect to the App Store,
    // which doesn't work reliably when opening a new tab (especially in Chrome).
    final opened = await launchUrl(
      Uri.parse(storeUrl),
      webOnlyWindowName: '_self',
    );

    if (!opened && mounted) {
      showSnackBar(
        context,
        'Unable to open the app store link.',
        type: SnackType.error,
      );
    }

    if (mounted) {
      setState(() => _isOpeningStore = false);
    }
  }

  Future<void> _continueOnWeb() async {
    await PrefService().setBool('mobile_web_continue', true);
    if (!mounted) return;

    final route = widget.nextRoute.isEmpty
        ? AppRoute.landingScreen
        : widget.nextRoute;
    context.go(route);
  }
}
