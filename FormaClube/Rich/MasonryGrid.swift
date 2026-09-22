import SwiftUI

/// Two or more columns of uneven rows. Use for collections, not for the hero question.
struct MasonryGrid<Item: Identifiable, Content: View>: View {
    var columns: Int = 2
    var items: [Item]
    @ViewBuilder var content: (Item) -> Content

    var body: some View {
        HStack(alignment: .top, spacing: AppMetrics.contentSpacing) {
            ForEach(0..<max(columns, 1), id: \.self) { column in
                LazyVStack(spacing: AppMetrics.contentSpacing) {
                    ForEach(itemsIn(column)) { item in
                        content(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func itemsIn(_ column: Int) -> [Item] {
        items.enumerated().compactMap { offset, item in
            offset % max(columns, 1) == column ? item : nil
        }
    }
}
