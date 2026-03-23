import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PaperSheetView: View {
    let text: String
    let phaseOneProgress: CGFloat
    let phaseTwoProgress: CGFloat
    let foldStage: FoldAnimationStage

    private let maximumFontSize: CGFloat = 16
    private let minimumFontSize: CGFloat = 9
    private let horizontalPadding: CGFloat = 18
    private let topPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 16
    private let frozenTextStripeCount = 18

    #if canImport(UIKit)
    @State private var frozenBottomTextStripes: [UIImage] = []
    @State private var frozenBottomTextSnapshotKey: FrozenBottomTextSnapshotKey?
    #endif

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let halfHeight = size.height / 2
            let progress = overallProgress
            let fontSize = fittedFontSize(in: size)

            ZStack(alignment: .top) {
                topHalf(
                    size: size,
                    halfHeight: halfHeight,
                    progress: progress,
                    fontSize: fontSize
                )
                    .zIndex(0)

                bottomHalf(
                    size: size,
                    halfHeight: halfHeight,
                    phaseOneProgress: phaseOneProgress,
                    phaseTwoProgress: phaseTwoProgress,
                    fontSize: fontSize
                )
                    .zIndex(1)
            }
            .onAppear {
                refreshFrozenBottomTextSnapshotIfNeeded(size: size, fontSize: fontSize)
            }
            .onChange(of: text) { _, _ in
                refreshFrozenBottomTextSnapshotIfNeeded(size: size, fontSize: fontSize)
            }
            .onChange(of: size) { _, newSize in
                refreshFrozenBottomTextSnapshotIfNeeded(
                    size: newSize,
                    fontSize: fittedFontSize(in: newSize)
                )
            }
            .onChange(of: foldStage) { _, newStage in
                guard newStage == .phaseOne else { return }
                refreshFrozenBottomTextSnapshotIfNeeded(size: size, fontSize: fontSize)
            }
        }
        .compositingGroup()
    }

    private var overallProgress: CGFloat {
        switch foldStage {
        case .idle:
            return 0
        case .phaseOne:
            return phaseOneProgress * 0.5
        case .phaseTwo, .folded:
            return 0.5 + phaseTwoProgress * 0.5
        }
    }

    private func topHalf(
        size: CGSize,
        halfHeight: CGFloat,
        progress: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let shadowStart = max(0, progress - 0.02) / 0.98
        let phaseTwo = max(0, progress - 0.5) * 2
        let shadowOpacity = 0.24 * shadowStart + 0.09 * phaseTwo

        return ZStack(alignment: .topLeading) {
            paperSurface(size: size, fontSize: fontSize, showsText: true)
        }
        .frame(width: size.width, height: halfHeight, alignment: .topLeading)
        .clipped()
        .overlay {
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(shadowOpacity)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(progress == 0 ? 0 : 1)
        }
    }

    @ViewBuilder
    private func bottomHalf(
        size: CGSize,
        halfHeight: CGFloat,
        phaseOneProgress: CGFloat,
        phaseTwoProgress: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        switch foldStage {
        case .idle, .phaseOne:
            bottomHalfPhaseOne(
                size: size,
                halfHeight: halfHeight,
                progress: phaseOneProgress,
                fontSize: fontSize
            )
        case .phaseTwo, .folded:
            bottomHalfPhaseTwo(
                size: size,
                halfHeight: halfHeight,
                progress: phaseTwoProgress,
                fontSize: fontSize
            )
        }
    }

    private func bottomHalfPhaseOne(
        size: CGSize,
        halfHeight: CGFloat,
        progress: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let maxOutset: CGFloat = 18
        let epsilon: CGFloat = 1.0
        let topY = halfHeight
        let bottomY = size.height - ((halfHeight - epsilon) * progress)
        let topOutset: CGFloat = 0
        let bottomOutset = maxOutset * progress
        let edgeOutset = bottomOutset
        let pieceWidth = size.width + edgeOutset * 2

        return bottomPaperSurface(
            pieceWidth: pieceWidth,
            sheetWidth: size.width,
            fullHeight: size.height,
            halfHeight: halfHeight,
            fontSize: fontSize,
            showsText: true,
            textDistortionProgress: progress
        )
            .offset(x: -edgeOutset)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .mask(
                FoldTrapezoidShape(
                    topY: topY,
                    bottomY: bottomY,
                    topOutset: topOutset,
                    bottomOutset: bottomOutset
                )
            )
    }

    private func bottomHalfPhaseTwo(
        size: CGSize,
        halfHeight: CGFloat,
        progress: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let maxOutset: CGFloat = 18
        let epsilon: CGFloat = 1.0
        let topY = (halfHeight - epsilon) * (1 - progress)
        let bottomY = halfHeight
        let topOutset = maxOutset * (1 - progress)
        let bottomOutset: CGFloat = 0
        let edgeOutset = topOutset
        let pieceWidth = size.width + edgeOutset * 2

        return bottomPaperSurface(
            pieceWidth: pieceWidth,
            sheetWidth: size.width,
            fullHeight: size.height,
            halfHeight: halfHeight,
            fontSize: fontSize,
            showsText: false,
            textDistortionProgress: 0
        )
            .offset(x: -edgeOutset)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
            .mask(
                FoldTrapezoidShape(
                    topY: topY,
                    bottomY: bottomY,
                    topOutset: topOutset,
                    bottomOutset: bottomOutset
                )
            )
    }

    private func bottomPaperSurface(
        pieceWidth: CGFloat,
        sheetWidth: CGFloat,
        fullHeight: CGFloat,
        halfHeight: CGFloat,
        fontSize: CGFloat,
        showsText: Bool,
        textDistortionProgress: CGFloat
    ) -> some View {
        let textInset = max(0, (pieceWidth - sheetWidth) / 2)

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.paperFill)
            if showsText {
                bottomTextLayer(
                    pieceWidth: pieceWidth,
                    sheetWidth: sheetWidth,
                    fullHeight: fullHeight,
                    halfHeight: halfHeight,
                    fontSize: fontSize,
                    textInset: textInset,
                    textDistortionProgress: textDistortionProgress
                )
            }
        }
        .frame(width: pieceWidth, height: fullHeight, alignment: .topLeading)
    }

    private func paperSurface(size: CGSize, fontSize: CGFloat, showsText: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.paperFill)
            if showsText {
                sheetText(
                    textWidth: size.width,
                    textHeight: size.height,
                    fontSize: fontSize
                )
            }
        }
    }

    private func sheetText(
        textWidth: CGFloat,
        textHeight: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundStyle(.black)
            .lineSpacing(lineSpacing(for: fontSize))
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .frame(width: textWidth, height: textHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private func bottomTextLayer(
        pieceWidth: CGFloat,
        sheetWidth: CGFloat,
        fullHeight: CGFloat,
        halfHeight: CGFloat,
        fontSize: CGFloat,
        textInset: CGFloat,
        textDistortionProgress: CGFloat
    ) -> some View {
        #if canImport(UIKit)
        if shouldUseFrozenBottomText(for: textDistortionProgress) {
            FrozenBottomTextView(
                stripes: frozenBottomTextStripes,
                sheetWidth: sheetWidth,
                pieceWidth: pieceWidth,
                fullHeight: fullHeight,
                halfHeight: halfHeight,
                progress: textDistortionProgress
            )
        } else {
            liveBottomText(
                sheetWidth: sheetWidth,
                fullHeight: fullHeight,
                fontSize: fontSize,
                textInset: textInset,
                textDistortionProgress: textDistortionProgress
            )
        }
        #else
        liveBottomText(
            sheetWidth: sheetWidth,
            fullHeight: fullHeight,
            fontSize: fontSize,
            textInset: textInset,
            textDistortionProgress: textDistortionProgress
        )
        #endif
    }

    private func liveBottomText(
        sheetWidth: CGFloat,
        fullHeight: CGFloat,
        fontSize: CGFloat,
        textInset: CGFloat,
        textDistortionProgress: CGFloat
    ) -> some View {
        sheetText(
            textWidth: sheetWidth,
            textHeight: fullHeight,
            fontSize: fontSize
        )
        .transformEffect(
            frontTextTransform(
                progress: textDistortionProgress,
                textWidth: sheetWidth,
                fullHeight: fullHeight
            )
        )
        .offset(x: textInset)
    }

    private func fittedFontSize(in size: CGSize) -> CGFloat {
        let availableWidth = max(1, size.width - horizontalPadding * 2)
        let availableHeight = max(1, size.height - topPadding - bottomPadding)
        let content = text.isEmpty ? " " : text

        var candidate = maximumFontSize
        while candidate >= minimumFontSize {
            if textHeight(for: content, fontSize: candidate, width: availableWidth) <= availableHeight {
                return candidate
            }

            candidate -= 0.5
        }

        return minimumFontSize
    }

    private func lineSpacing(for fontSize: CGFloat) -> CGFloat {
        max(1.5, fontSize * 0.18)
    }

    private func frontTextTransform(
        progress: CGFloat,
        textWidth: CGFloat,
        fullHeight: CGFloat
    ) -> CGAffineTransform {
        let delayedProgress = max(0, (progress - 0.18) / 0.82)
        guard delayedProgress > 0 else { return .identity }

        let easedProgress = delayedProgress * delayedProgress
        let anchor = CGPoint(x: horizontalPadding, y: fullHeight / 2)
        let xScale = 1 + easedProgress * 0.025
        let yScale = 1 - easedProgress * 0.11
        let shear = easedProgress * 0.015

        return CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .concatenating(
                CGAffineTransform(
                    a: xScale,
                    b: 0,
                    c: shear,
                    d: yScale,
                    tx: 0,
                    ty: 0
                )
            )
            .concatenating(CGAffineTransform(translationX: -anchor.x, y: -anchor.y))
    }

    #if canImport(UIKit)
    private func shouldUseFrozenBottomText(for progress: CGFloat) -> Bool {
        foldStage == .phaseOne && !frozenBottomTextStripes.isEmpty && progress >= 0
    }

    private func refreshFrozenBottomTextSnapshotIfNeeded(size: CGSize, fontSize: CGFloat) {
        let roundedSize = CGSize(width: size.width.rounded(.toNearestOrAwayFromZero), height: size.height.rounded(.toNearestOrAwayFromZero))
        let snapshotKey = FrozenBottomTextSnapshotKey(
            text: text,
            size: roundedSize,
            fontSize: fontSize
        )

        guard frozenBottomTextSnapshotKey != snapshotKey || frozenBottomTextStripes.isEmpty else {
            return
        }

        guard roundedSize.width > 1, roundedSize.height > 1 else {
            frozenBottomTextSnapshotKey = nil
            frozenBottomTextStripes = []
            return
        }

        let renderer = ImageRenderer(
            content: sheetText(
                textWidth: roundedSize.width,
                textHeight: roundedSize.height,
                fontSize: fontSize
            )
        )
        renderer.proposedSize = ProposedViewSize(roundedSize)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else {
            frozenBottomTextSnapshotKey = nil
            frozenBottomTextStripes = []
            return
        }

        frozenBottomTextSnapshotKey = snapshotKey
        frozenBottomTextStripes = makeBottomTextStripes(from: image)
    }

    private func makeBottomTextStripes(from image: UIImage) -> [UIImage] {
        guard let cgImage = image.cgImage else { return [] }

        let halfPixelHeight = max(1, cgImage.height / 2)
        let stripeHeight = max(1, Int(ceil(CGFloat(halfPixelHeight) / CGFloat(frozenTextStripeCount))))

        return (0..<frozenTextStripeCount).compactMap { index in
            let y = halfPixelHeight + index * stripeHeight
            guard y < cgImage.height else { return nil }

            let cropHeight = min(stripeHeight + 1, cgImage.height - y)
            let cropRect = CGRect(
                x: 0,
                y: y,
                width: cgImage.width,
                height: cropHeight
            )

            guard let rowImage = cgImage.cropping(to: cropRect) else { return nil }

            return UIImage(cgImage: rowImage, scale: image.scale, orientation: .up)
        }
    }
    #endif

    private func textHeight(for text: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        #if canImport(UIKit)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = lineSpacing(for: fontSize)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]

        let boundingRect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        return ceil(boundingRect.height)
        #else
        return .greatestFiniteMagnitude
        #endif
    }
}

#if canImport(UIKit)
private struct FrozenBottomTextSnapshotKey: Equatable {
    let text: String
    let size: CGSize
    let fontSize: CGFloat
}

private struct FrozenBottomTextView: View {
    let stripes: [UIImage]
    let sheetWidth: CGFloat
    let pieceWidth: CGFloat
    let fullHeight: CGFloat
    let halfHeight: CGFloat
    let progress: CGFloat

    var body: some View {
        let clampedProgress = min(max(progress, 0), 1)
        let pieceHeight = max(1, halfHeight * (1 - clampedProgress))

        ZStack(alignment: .topLeading) {
            ForEach(Array(stripes.enumerated()), id: \.offset) { index, stripe in
                let start = CGFloat(index) / CGFloat(stripes.count)
                let end = CGFloat(index + 1) / CGFloat(stripes.count)
                let center = (start + end) / 2
                let rowWidth = sheetWidth + (pieceWidth - sheetWidth) * center
                let rowX = (pieceWidth - rowWidth) / 2
                let rowY = halfHeight + pieceHeight * start
                let rowHeight = max(1, pieceHeight * (end - start) + 0.75)

                Image(uiImage: stripe)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: rowWidth, height: rowHeight)
                    .offset(x: rowX, y: rowY)
            }
        }
        .frame(width: pieceWidth, height: fullHeight, alignment: .topLeading)
    }
}
#endif

private struct FoldTrapezoidShape: Shape {
    var topY: CGFloat
    var bottomY: CGFloat
    var topOutset: CGFloat
    var bottomOutset: CGFloat

    var animatableData: AnimatablePair<
        CGFloat,
        AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>
    > {
        get {
            AnimatablePair(
                topY,
                AnimatablePair(
                    bottomY,
                    AnimatablePair(topOutset, bottomOutset)
                )
            )
        }
        set {
            topY = newValue.first
            bottomY = newValue.second.first
            topOutset = newValue.second.second.first
            bottomOutset = newValue.second.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - topOutset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX + topOutset, y: topY))
        path.addLine(to: CGPoint(x: rect.maxX + bottomOutset, y: bottomY))
        path.addLine(to: CGPoint(x: rect.minX - bottomOutset, y: bottomY))
        path.closeSubpath()
        return path
    }
}
