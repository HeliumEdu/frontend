// Copyright (c) Helium Edu
//
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:heliumapp/utils/print_helpers.dart';

class ResponsiveCardGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double maxCardWidth;
  final double crossAxisSpacing;
  final bool shrinkWrap;

  /// When true, wraps each row (or single-column item) in a [PrintPageBreak]
  /// so the PDF slicer never cuts through a card mid-content.
  final bool printPageBreakAfterRow;

  const ResponsiveCardGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.maxCardWidth = 390,
    this.crossAxisSpacing = 12.0,
    this.shrinkWrap = false,
    this.printPageBreakAfterRow = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columnsCount = (availableWidth / (maxCardWidth + crossAxisSpacing))
            .floor()
            .clamp(1, double.infinity)
            .toInt();

        if (columnsCount == 1) {
          // Single column can use ListView directly for better performance
          return ListView.builder(
            shrinkWrap: shrinkWrap,
            physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = itemBuilder(context, items[index]);
              return printPageBreakAfterRow
                  ? PrintPageBreak(child: item)
                  : item;
            },
          );
        }

        final rowCount = (items.length / columnsCount).ceil();

        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            final startIndex = rowIndex * columnsCount;
            final endIndex = (startIndex + columnsCount).clamp(0, items.length);
            final rowItems = items.sublist(startIndex, endIndex);

            final row = LayoutBuilder(
              builder: (context, rowConstraints) {
                final cardWidth = (rowConstraints.maxWidth -
                        (crossAxisSpacing * (columnsCount - 1))) /
                    columnsCount;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rowItems.length; i++) ...[
                      if (i > 0) SizedBox(width: crossAxisSpacing),
                      SizedBox(
                        width: cardWidth,
                        child: itemBuilder(context, rowItems[i]),
                      ),
                    ],
                    if (rowItems.length < columnsCount)
                      ...List.generate(
                        columnsCount - rowItems.length,
                        (index) => SizedBox(width: cardWidth),
                      ),
                  ],
                );
              },
            );
            return printPageBreakAfterRow ? PrintPageBreak(child: row) : row;
          },
        );
      },
    );
  }
}
