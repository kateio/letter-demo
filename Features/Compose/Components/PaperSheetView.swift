import SwiftUI

struct PaperSheetView: View {
    let text: String
    let phaseOneProgress: CGFloat
    let phaseTwoProgress: CGFloat
    let foldStage: FoldAnimationStage

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let halfHeight = size.height / 2
            let progress = overallProgress

            ZStack(alignment: .top) {
                topHalf(size: size, halfHeight: halfHeight, progress: progress)
                    .zIndex(0)

                bottomHalf(
                    size: size,
                    halfHeight: halfHeight,
                    phaseOneProgress: phaseOneProgress,
                    phaseTwoProgress: phaseTwoProgress
                )
                    .zIndex(1)
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

    private func topHalf(size: CGSize, halfHeight: CGFloat, progress: CGFloat) -> some View {
        let shadowStart = max(0, progress - 0.02) / 0.98
        let phaseTwo = max(0, progress - 0.5) * 2
        let shadowOpacity = 0.30 * shadowStart + 0.12 * phaseTwo

        return ZStack(alignment: .topLeading) {
            paperSurface(size: size)
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
        phaseTwoProgress: CGFloat
    ) -> some View {
        switch foldStage {
        case .idle, .phaseOne:
            bottomHalfPhaseOne(
                size: size,
                halfHeight: halfHeight,
                progress: phaseOneProgress
            )
        case .phaseTwo, .folded:
            bottomHalfPhaseTwo(
                size: size,
                halfHeight: halfHeight,
                progress: phaseTwoProgress
            )
        }
    }

    private func bottomHalfPhaseOne(
        size: CGSize,
        halfHeight: CGFloat,
        progress: CGFloat
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
            fullHeight: size.height,
            halfHeight: halfHeight
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
        progress: CGFloat
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
            fullHeight: size.height,
            halfHeight: halfHeight
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
        fullHeight: CGFloat,
        halfHeight: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.paperFill)
            sheetText()
                .frame(width: pieceWidth, height: fullHeight, alignment: .topLeading)
                .offset(y: -halfHeight)
        }
        .frame(width: pieceWidth, height: fullHeight, alignment: .topLeading)
    }

    private func paperSurface(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(AppColors.paperFill)
            sheetText()
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }

    private func sheetText() -> some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.black)
            .lineSpacing(3)
            .padding(.horizontal, 18)
            .padding(.top, 16)
    }
}

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
