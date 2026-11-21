import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/utils/app_globals.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/date_time_helpers.dart';
import 'package:heliumapp/utils/planner_helper.dart';
import 'package:heliumapp/utils/print_helpers.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PlannerDateNavigator extends StatelessWidget {
  static const String calendarPrevButtonKey = 'planner_calendar_prev_button';
  static const String calendarNextButtonKey = 'planner_calendar_next_button';

  final PlannerView currentView;
  final CalendarController calendarController;
  final VoidCallback onOpenDatePicker;
  final String? labelOverride;

  const PlannerDateNavigator({
    super.key,
    required this.currentView,
    required this.calendarController,
    required this.onOpenDatePicker,
    this.labelOverride,
  });

  /// Shared height for the calendar header controls: 40 normally, 36 on slim
  /// phones so the row fits without overflowing (matches the chevrons/date).
  static double headerButtonSize(BuildContext context) =>
      Responsive.isSlimMobile(context) ? 36 : 40;

  @override
  Widget build(BuildContext context) {
    if (currentView == PlannerView.todos) {
      return Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              CalendarConstants
                  .defaultViews[PlannerHelper.mapHeliumViewToApiView(
                currentView,
              )],
              style: AppStyles.headingText(
                context,
              ).copyWith(color: context.colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    final String headerText = labelOverride ?? _buildHeaderDate(context);

    final showNavButtons =
        currentView != PlannerView.agenda &&
        !Responsive.isNarrowMobile(context);
    final bool isSlimMobile = Responsive.isSlimMobile(context);
    final double chevronGap = isSlimMobile ? 2 : 3;
    final double chevronSize = headerButtonSize(context);
    final double leadingGap = isSlimMobile
        ? 2
        : (Responsive.isMobile(context) ? 4 : 8);

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: leadingGap),
          if (!showNavButtons) const SizedBox(width: 4),
          if (showNavButtons) ...[
            PrintHidden(
              child: IconButton(
                key: const Key(calendarPrevButtonKey),
                icon: Icon(
                  Icons.chevron_left,
                  color: context.colorScheme.primary,
                  semanticLabel: 'Previous',
                ),
                onPressed: calendarController.backward,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: chevronSize,
                  minHeight: chevronSize,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            SizedBox(width: chevronGap),
          ],
          Stack(
            alignment: Alignment.center,
            children: [
              for (final sample in _calendarHeaderSamples(context))
                Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildHeaderLabelRow(context, sample),
                ),
              Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onOpenDatePicker,
                    borderRadius: BorderRadius.circular(6),
                    child: _buildHeaderLabelRow(context, headerText),
                  ),
                ),
              ),
            ],
          ),
          if (showNavButtons)
            SizedBox(width: Responsive.isMobile(context) ? 2 : 4),
          if (showNavButtons)
            PrintHidden(
              child: IconButton(
                key: const Key(calendarNextButtonKey),
                icon: Icon(
                  Icons.chevron_right,
                  color: context.colorScheme.primary,
                  semanticLabel: 'Next',
                ),
                onPressed: calendarController.forward,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: chevronSize,
                  minHeight: chevronSize,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildHeaderDate(BuildContext context) {
    return HeliumDateTime.formatMonthAndYear(
      calendarController.displayDate!,
      abbreviateMonth: Responsive.isCompact(context),
    );
  }

  /// Sample labels for every month in the current view's format. Used to
  /// reserve a fixed-width slot for the header label so the chevrons don't
  /// shift as the user pages between months. Sampled rather than measured
  /// via TextPainter so the size honors the real font (GoogleFonts loads
  /// asynchronously, so TextPainter can disagree with the paint pass).
  List<String> _calendarHeaderSamples(BuildContext context) {
    final isCompact = Responsive.isCompact(context);

    return List.generate(12, (i) {
      return HeliumDateTime.formatMonthAndYear(
        DateTime(2025, i + 1, 25),
        abbreviateMonth: isCompact,
      );
    });
  }

  Widget _buildHeaderLabelRow(BuildContext context, String text) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isSlimMobile = Responsive.isSlimMobile(context);
    final double sideInset = isMobile ? (isSlimMobile || kIsWeb ? 2 : 4) : 8;
    const double webInset = kIsWeb ? 4 : 0;
    // Vertical padding + the 24px dropdown icon sets the date height to match
    // the header's chevrons: 8+24+8 = 40 normally, 6+24+6 = 36 on slim phones.
    final double vInset = isSlimMobile ? 6 : 8;
    return Padding(
      padding: EdgeInsets.only(
        left: sideInset + webInset,
        right: kIsWeb ? webInset : (isSlimMobile ? 0 : 4),
        top: vInset,
        bottom: vInset,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            style: AppStyles.headingText(context).copyWith(
              color: context.colorScheme.onSurface,
              // Trim the date 1pt on slim phones to reclaim the last few pixels
              // the header row needs to fit.
              fontSize: isSlimMobile ? 14 : null,
            ),
          ),
          const SizedBox(width: 2),
          PrintHidden(
            child: SizedBox(
              // The arrow_drop_down glyph carries ~4px of empty optical padding
              // on its trailing edge; reserve a narrower box so the right
              // chevron pulls in to stay symmetric with the tightened left
              // inset above.
              width: isMobile ? 18 : 24,
              height: 24,
              child: OverflowBox(
                maxWidth: 24,
                maxHeight: 24,
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_drop_down,
                  color: context.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlannerTodayButton extends StatelessWidget {
  final bool showLabel;
  final Key? buttonKey;
  final VoidCallback onPressed;

  const PlannerTodayButton({
    super.key,
    required this.showLabel,
    this.buttonKey,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.calendar_today,
      size: Responsive.getIconSize(
        context,
        mobile: 20,
        tablet: 22,
        desktop: 24,
      ),
      semanticLabel: showLabel ? null : 'Today',
    );
    if (showLabel) {
      return OutlinedButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        icon: icon,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          // Pin height to match the other header controls on both mobile and
          // web. Standard density keeps it fixed so it stays aligned with the
          // density-fixed icon buttons (and the non-button date field).
          minimumSize: WidgetStateProperty.all(
            Size(0, PlannerDateNavigator.headerButtonSize(context)),
          ),
          maximumSize: WidgetStateProperty.all(
            Size(
              double.infinity,
              PlannerDateNavigator.headerButtonSize(context),
            ),
          ),
          visualDensity: VisualDensity.standard,
          side: WidgetStateProperty.all(
            BorderSide(color: context.colorScheme.primary),
          ),
        ),
        label: Text(
          'Today',
          style: AppStyles.buttonText(
            context,
          ).copyWith(color: context.colorScheme.primary),
        ),
      );
    } else {
      return IconButton.outlined(
        key: buttonKey,
        onPressed: onPressed,
        icon: icon,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size(
            PlannerDateNavigator.headerButtonSize(context),
            PlannerDateNavigator.headerButtonSize(context),
          ),
          side: BorderSide(color: context.colorScheme.primary),
        ),
      );
    }
  }
}
