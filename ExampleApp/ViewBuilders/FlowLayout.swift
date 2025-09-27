//
//  FlowLayout.swift
//  ExampleApp
//
//  Created for wrapping horizontal content
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, row) in result.rows.enumerated() {
            let rowYOffset = result.rowOffsets[index]
            var xOffset: CGFloat = 0

            for item in row {
                let itemSize = item.sizeThatFits(.unspecified)
                item.place(
                    at: CGPoint(x: bounds.minX + xOffset, y: bounds.minY + rowYOffset),
                    proposal: ProposedViewSize(itemSize)
                )
                xOffset += itemSize.width + spacing
            }
        }
    }

    struct FlowResult {
        var rows: [[LayoutSubviews.Element]] = []
        var rowOffsets: [CGFloat] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentRow: [LayoutSubviews.Element] = []
            var currentRowWidth: CGFloat = 0
            var currentRowMaxHeight: CGFloat = 0
            var totalHeight: CGFloat = 0
            var maxRowWidth: CGFloat = 0

            for subview in subviews {
                let itemSize = subview.sizeThatFits(.unspecified)

                // Check if adding this item would exceed the width
                if !currentRow.isEmpty && currentRowWidth + spacing + itemSize.width > maxWidth {
                    // Finish current row
                    rows.append(currentRow)
                    rowOffsets.append(totalHeight)
                    totalHeight += currentRowMaxHeight + spacing
                    maxRowWidth = max(maxRowWidth, currentRowWidth)

                    // Start new row
                    currentRow = [subview]
                    currentRowWidth = itemSize.width
                    currentRowMaxHeight = itemSize.height
                } else {
                    // Add to current row
                    currentRow.append(subview)
                    if !currentRow.isEmpty && currentRow.count > 1 {
                        currentRowWidth += spacing
                    }
                    currentRowWidth += itemSize.width
                    currentRowMaxHeight = max(currentRowMaxHeight, itemSize.height)
                }
            }

            // Add the last row
            if !currentRow.isEmpty {
                rows.append(currentRow)
                rowOffsets.append(totalHeight)
                totalHeight += currentRowMaxHeight
                maxRowWidth = max(maxRowWidth, currentRowWidth)
            }

            size = CGSize(width: maxRowWidth, height: totalHeight)
        }
    }
}