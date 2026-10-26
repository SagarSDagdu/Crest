import SwiftUI

struct BrowserCommandPalettePresentationView: View {
    let model: BrowserCommandPaletteModel
    let presentation: BrowserCommandPalettePresentation
    let morphNamespace: Namespace.ID?
    let overlayContentLeadingInset: CGFloat
    var overlayContentInsets: EdgeInsets? = nil
    /// Nil where the host doesn't let the overlay card move.
    var overlayOffset: Binding<CGSize>? = nil
    let queryIsFocused: FocusState<Bool>.Binding

    @GestureState private var dragTranslation = CGSize.zero
    @State private var cardHeight: CGFloat = 0

    @ViewBuilder
    var body: some View {
        if presentation == .overlay {
            GeometryReader { proxy in
                let availableSize = CGSize(
                    width: proxy.size.width - contentInsets.leading - contentInsets.trailing,
                    height: proxy.size.height - contentInsets.top - contentInsets.bottom)
                let maximumResultAreaHeight =
                    BrowserCommandPaletteLayout
                    .overlayResultAreaHeight(availableHeight: availableSize.height)
                let cardWidth = BrowserCommandPaletteLayout.overlayCardWidth(availableWidth: availableSize.width)
                let cardSize = CGSize(width: cardWidth, height: cardHeight)
                let offset = BrowserCommandPaletteLayout.overlayOffset(
                    movedOffset, cardSize: cardSize, availableSize: availableSize)

                ZStack {
                    BrowserCommandPaletteScrim(dismiss: model.dismiss)
                    BrowserCommandPaletteCard(
                        model: model,
                        presentation: presentation,
                        maximumResultAreaHeight: maximumResultAreaHeight,
                        morphNamespace: morphNamespace,
                        restingWidth: cardWidth,
                        queryIsFocused: queryIsFocused
                    )
                    .frame(width: cardWidth)
                    .onGeometryChange(for: CGFloat.self) {
                        $0.size.height
                    } action: {
                        cardHeight = $0
                    }
                    // Behind the contents, so rows and the field keep their drags, and the card's
                    // empty areas don't fall through to the scrim, which dismisses.
                    .background {
                        RoundedRectangle(
                            cornerRadius: BrowserCommandPaletteMetrics.cardCornerRadius, style: .continuous
                        )
                        .fill(.clear)
                        .contentShape(
                            RoundedRectangle(
                                cornerRadius: BrowserCommandPaletteMetrics.cardCornerRadius, style: .continuous)
                        )
                        .gesture(
                            moveGesture(cardSize: cardSize, availableSize: availableSize),
                            isEnabled: overlayOffset != nil
                        )
                    }
                    // Padding, not .offset: the address field morph reads layout frames.
                    .padding(.leading, (availableSize.width - cardWidth) / 2 + offset.width)
                    .padding(
                        .top,
                        BrowserCommandPaletteLayout.overlayTopInset(availableHeight: availableSize.height)
                            + offset.height
                    )
                    .padding(.bottom, BrowserCommandPaletteMetrics.overlayCardPadding)
                    // The top edge stays put while results change; the card grows down.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(contentInsets)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            BrowserCommandPaletteCard(
                model: model,
                presentation: presentation,
                maximumResultAreaHeight: BrowserCommandPaletteLayout.maximumResultAreaHeight,
                morphNamespace: nil,
                restingWidth: nil,
                queryIsFocused: queryIsFocused
            )
        }
    }

    private var movedOffset: CGSize {
        let kept = overlayOffset?.wrappedValue ?? .zero
        return CGSize(width: kept.width + dragTranslation.width, height: kept.height + dragTranslation.height)
    }

    /// Only fires on empty parts of the card; the field, buttons and rows keep their own clicks.
    private func moveGesture(cardSize: CGSize, availableSize: CGSize) -> some Gesture {
        // Global, since the card's own space moves with the drag.
        DragGesture(minimumDistance: BrowserCommandPaletteMetrics.moveDragThreshold, coordinateSpace: .global)
            .updating($dragTranslation) { value, translation, _ in translation = value.translation }
            .onEnded { value in
                guard let overlayOffset else { return }
                let kept = overlayOffset.wrappedValue
                overlayOffset.wrappedValue = BrowserCommandPaletteLayout.overlayOffset(
                    CGSize(width: kept.width + value.translation.width, height: kept.height + value.translation.height),
                    cardSize: cardSize, availableSize: availableSize)
            }
    }

    /// The part of the overlay the page's chrome keeps, which the card and
    /// its results stay clear of.
    private var contentInsets: EdgeInsets {
        overlayContentInsets
            ?? EdgeInsets(top: 0, leading: overlayContentLeadingInset, bottom: 0, trailing: 0)
    }
}
