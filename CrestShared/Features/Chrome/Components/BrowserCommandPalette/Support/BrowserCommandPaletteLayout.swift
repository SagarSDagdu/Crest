import CoreGraphics

enum BrowserCommandPaletteLayout {
    static let maximumResultAreaHeight = BrowserCommandPaletteMetrics.maximumResultAreaHeight

    /// The height the results take: each group's rows, with a header above
    /// a group that has one, the spacing between groups and the padding
    /// around them, at most `maximumHeight`.
    static func resultAreaHeight(
        groups: [(hasHeader: Bool, rows: Int)],
        maximumHeight: CGFloat = maximumResultAreaHeight
    ) -> CGFloat {
        let shown = groups.filter { $0.rows > 0 }
        guard !shown.isEmpty else { return 0 }
        let groupsHeight = shown.reduce(CGFloat.zero) { total, group in
            total
                + (group.hasHeader
                    ? BrowserCommandPaletteMetrics.resultHeaderHeight + BrowserCommandPaletteMetrics.resultRowSpacing
                    : 0)
                + CGFloat(group.rows) * BrowserCommandPaletteMetrics.resultRowHeight
                + CGFloat(group.rows - 1) * BrowserCommandPaletteMetrics.resultRowSpacing
        }
        let spacing = CGFloat(shown.count - 1) * BrowserCommandPaletteMetrics.resultSectionSpacing
        return min(BrowserCommandPaletteMetrics.resultOuterPadding + groupsHeight + spacing, max(0, maximumHeight))
    }

    static func resultAreaHeight(
        tabCount: Int,
        includesPrimaryAction: Bool,
        maximumHeight: CGFloat = maximumResultAreaHeight
    ) -> CGFloat {
        resultAreaHeight(
            groups: [(false, includesPrimaryAction ? 1 : 0), (true, max(0, tabCount))],
            maximumHeight: maximumHeight
        )
    }

    /// The overlay card's width in the space its layer leaves it: as wide as
    /// the palette allows, less the padding around the card.
    static func overlayCardWidth(availableWidth: CGFloat) -> CGFloat {
        min(
            BrowserCommandPaletteMetrics.maximumCardWidth,
            max(0, availableWidth - BrowserCommandPaletteMetrics.overlayCardPadding * 2)
        )
    }

    /// How far below the top of the space its layer leaves it the overlay
    /// card's top edge rests: where a card with its tallest results would sit
    /// centered, so the top never moves as results come and go and the card
    /// only grows downward, as on iPhone and iPad.
    static func overlayTopInset(availableHeight: CGFloat) -> CGFloat {
        let tallestCard =
            BrowserCommandPaletteMetrics.searchFieldMinimumHeight
            + overlayResultAreaHeight(availableHeight: availableHeight)
        return max(BrowserCommandPaletteMetrics.overlayCardPadding, (availableHeight - tallestCard) / 2)
    }

    /// Keeps the card padding on every side; an axis with no room to move stays at rest.
    static func overlayOffset(_ offset: CGSize, cardSize: CGSize, availableSize: CGSize) -> CGSize {
        let padding = BrowserCommandPaletteMetrics.overlayCardPadding
        let restingLeading = (availableSize.width - cardSize.width) / 2
        let restingTop = overlayTopInset(availableHeight: availableSize.height)
        func clamped(_ value: CGFloat, resting: CGFloat, room: CGFloat) -> CGFloat {
            let lower = padding - resting
            let upper = room - padding - resting
            return upper < lower ? 0 : min(max(value, lower), upper)
        }
        return CGSize(
            width: clamped(offset.width, resting: restingLeading, room: availableSize.width - cardSize.width),
            height: clamped(offset.height, resting: restingTop, room: availableSize.height - cardSize.height))
    }

    static func overlayResultAreaHeight(availableHeight: CGFloat) -> CGFloat {
        max(
            BrowserCommandPaletteMetrics.minimumOverlayResultHeight,
            min(
                maximumResultAreaHeight,
                availableHeight - BrowserCommandPaletteMetrics.overlayReservedHeight
            )
        )
    }

}
