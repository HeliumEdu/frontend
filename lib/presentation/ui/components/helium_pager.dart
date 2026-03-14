// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';
import 'package:heliumapp/config/app_theme.dart';
import 'package:heliumapp/data/models/drop_down_item.dart';
import 'package:heliumapp/presentation/ui/components/drop_down.dart';
import 'package:heliumapp/utils/app_style.dart';
import 'package:heliumapp/utils/responsive_helpers.dart';

class HeliumPager extends StatelessWidget {
  final int startIndex;
  final int endIndex;
  final int totalItems;
  final bool isShowingAll;
  final int totalPages;
  final int currentPage;
  final void Function(int) onPageChanged;
  final int itemsPerPage;
  final List<int> itemsPerPageOptions;
  final void Function(int)? onItemsPerPageChanged;

  const HeliumPager({
    super.key,
    required this.startIndex,
    required this.endIndex,
    required this.totalItems,
    required this.isShowingAll,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
    required this.itemsPerPage,
    required this.itemsPerPageOptions,
    this.onItemsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: 8,
        top: Responsive.isMobile(context) ? 4 : 8,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItemsCountText(context),
              if (!isShowingAll && totalPages > 1)
                _buildPagination(context),
            ],
          ),
          const SizedBox(height: 4),
          if (onItemsPerPageChanged != null)
            _buildItemsPerPageDropdown(context),
        ],
      ),
    );
  }

  Widget _buildItemsCountText(BuildContext context) {
    final displayStart = totalItems > 0 ? startIndex + 1 : 0;
    return Text(
      '${!Responsive.isMobile(context) ? 'Showing ' : ''}$displayStart to $endIndex of $totalItems',
      style: AppStyles.standardBodyTextLight(context).copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Row(
      children: [
        if (isMobile)
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            icon: const Icon(Icons.first_page),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (isMobile) const SizedBox(width: 4),
        IconButton(
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        ..._buildPageNumbers(context, isMobile),
        const SizedBox(width: 8),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (isMobile) const SizedBox(width: 4),
        if (isMobile)
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(totalPages) : null,
            icon: const Icon(Icons.last_page),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(BuildContext context, bool isMobile) {
    final List<Widget> pages = [];

    if (isMobile) {
      // On mobile: show up to 3 pages centered around current, no ellipsis
      const int maxVisible = 3;
      final int start = (currentPage - 1)
          .clamp(1, (totalPages - maxVisible + 1).clamp(1, totalPages));
      final int end = (start + maxVisible - 1).clamp(1, totalPages);
      for (int i = start; i <= end; i++) {
        pages.add(_buildPageButton(context, i));
      }
    } else {
      // Desktop: full ellipsis behavior
      const int maxVisiblePages = 5;
      if (totalPages <= maxVisiblePages) {
        for (int i = 1; i <= totalPages; i++) {
          pages.add(_buildPageButton(context, i));
        }
      } else {
        pages.add(_buildPageButton(context, 1));

        final int start = (currentPage - 1).clamp(2, totalPages - 3);
        final int end = (currentPage + 1).clamp(4, totalPages - 1);

        if (start > 2) {
          pages.add(_buildEllipsis(context));
        }

        for (int i = start; i <= end; i++) {
          pages.add(_buildPageButton(context, i));
        }

        if (end < totalPages - 1) {
          pages.add(_buildEllipsis(context));
        }

        pages.add(_buildPageButton(context, totalPages));
      }
    }

    return pages;
  }

  Widget _buildPageButton(BuildContext context, int pageNumber) {
    final isActive = currentPage == pageNumber;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OutlinedButton(
        onPressed: isActive ? null : () => onPageChanged(pageNumber),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? context.colorScheme.primary
              : context.colorScheme.surface,
          disabledBackgroundColor: isActive
              ? context.colorScheme.primary
              : null,
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          side: BorderSide(color: context.colorScheme.primary),
        ),
        child: Text(
          pageNumber.toString(),
          style: AppStyles.buttonText(context).copyWith(
            color: isActive
                ? context.colorScheme.onPrimary
                : context.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '...',
          style: AppStyles.standardBodyTextLight(context).copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPerPageDropdown(BuildContext context) {
    final dropDownItems = itemsPerPageOptions.map((value) {
      return DropDownItem<String>(
        id: value,
        value: value == -1 ? 'All' : value.toString(),
      );
    }).toList();

    final currentItem = dropDownItems.firstWhere(
      (item) => item.id == itemsPerPage,
      orElse: () => dropDownItems.first,
    );

    return Row(
      children: [
        Text(
          'Show',
          style: AppStyles.standardBodyTextLight(context).copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: DropDown<String>(
            initialValue: currentItem,
            items: dropDownItems,
            onChanged: (newItem) {
              if (newItem != null) {
                onItemsPerPageChanged!(newItem.id);
              }
            },
          ),
        ),
      ],
    );
  }
}
