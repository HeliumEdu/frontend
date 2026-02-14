// Copyright (c) 2025 Helium Edu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// For details regarding the license, please refer to the LICENSE file.

import 'package:flutter/material.dart';

class ResponsiveCardGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double maxCardWidth;
  final double crossAxisSpacing;

  const ResponsiveCardGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.maxCardWidth = 350.0,
    this.crossAxisSpacing = 12.0,
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              return itemBuilder(context, items[index]);
            },
          );
        }

        final rowCount = (items.length / columnsCount).ceil();

        return ListView.builder(
          itemCount: rowCount,
          itemBuilder: (context, rowIndex) {
            final startIndex = rowIndex * columnsCount;
            final endIndex = (startIndex + columnsCount).clamp(0, items.length);
            final rowItems = items.sublist(startIndex, endIndex);

            return LayoutBuilder(
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
          },
        );
      },
    );
  }
}
