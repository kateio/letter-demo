import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum FoldAnimationStage {
    case idle
    case phaseOne
    case phaseTwo
    case folded
}

struct ComposeLetterView: View {
    @State private var stage: ComposeStage = .editing
    @State private var draft = LetterDraft()
    @State private var isFolded = false
    @State private var phaseOneProgress: CGFloat = 0
    @State private var phaseTwoProgress: CGFloat = 0
    @State private var foldStage: FoldAnimationStage = .idle
    @State private var isFoldAnimating = false
    @State private var isPreviewOverlayVisible = false
    @FocusState private var isInputFocused: Bool
    private let previewSheetSize = CGSize(width: 332, height: 476)
    private let previewTransitionDuration: Double = 0.35
    private let previewOverlayDelay: Double = 0.12

    var body: some View {
        ZStack {
            AppColors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ZStack {
                    if stage == .editing || stage == .transitioningToPreview {
                        editingScreen
                            .allowsHitTesting(stage == .editing)
                    }

                    if stage == .transitioningToPreview || stage == .paperPreview {
                        AppColors.screenBackground
                            .opacity(stage == .transitioningToPreview ? 0.22 : 0)
                            .ignoresSafeArea()

                        previewScreen(showFoldButton: stage == .paperPreview)
                            .opacity(previewOverlayOpacity)
                            .transition(.opacity)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: stage)
        .onAppear {
            isInputFocused = true
        }
    }

    private var topBar: some View {
        GlassEffectContainer(spacing: 12) {
            ZStack {
                topBarForegroundContent
                    .opacity(topBarForegroundOpacity)
                    .blur(radius: topBarForegroundBlur)

                HStack(spacing: 8) {
                    topBarCircleButton(systemName: "chevron.left", iconSize: 21) {
                        handleBack()
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, AppSpacing.topBar)
        .padding(.bottom, 20)
    }

    private var topBarForegroundContent: some View {
        ZStack {
            Text(draft.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 64)

            HStack {
                Spacer()
                topBarTrailingContent
            }
        }
    }

    private func topBarCircleButton(
        systemName: String,
        iconSize: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: Circle())
    }

    private var editingScreen: some View {
        editingContent
    }

    private var editingContent: some View {
        VStack(spacing: 24) {
            letterContainer(isPreview: false)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.horizontal)
        .blur(radius: stage == .transitioningToPreview ? 14 : 0)
        .opacity(stage == .transitioningToPreview ? 0.58 : 1)
        .scaleEffect(stage == .transitioningToPreview ? 0.985 : 1)
    }

    private func previewScreen(showFoldButton: Bool) -> some View {
        VStack(spacing: 0) {
            previewContent(showFoldButton: showFoldButton)
        }
        .overlay(alignment: .bottom) {
            if showFoldButton {
                foldButton
                    .padding(.horizontal, AppSpacing.horizontal)
                    .padding(.bottom, 40)
                    .transition(.opacity)
            }
        }
    }

    private func previewContent(showFoldButton: Bool) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)

            letterContainer(isPreview: true)
                .offset(y: -56)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.horizontal)
    }

    private var topBarTrailingContent: some View {
        Group {
            if stage == .editing {
                topBarCircleButton(systemName: "checkmark", iconSize: 18) {
                    saveLetter()
                }
                .allowsHitTesting(true)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var foldButton: some View {
        Button(isFolded ? "Развернуть" : "Свернуть") {
            toggleFold()
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .disabled(isFoldAnimating)
    }

    private func letterContainer(isPreview: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            if isPreview {
                PaperSheetView(
                    text: draft.body,
                    phaseOneProgress: phaseOneProgress,
                    phaseTwoProgress: phaseTwoProgress,
                    foldStage: foldStage
                )
                .allowsHitTesting(false)
            } else {
                TextEditor(text: $draft.body)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.black)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .focused($isInputFocused)
                    .padding(.horizontal, 13)
                    .padding(.top, 8)
            }
        }
        .frame(
            minWidth: isPreview ? previewSheetSize.width : nil,
            maxWidth: isPreview ? previewSheetSize.width : .infinity,
            minHeight: isPreview ? previewSheetSize.height : nil,
            maxHeight: isPreview ? previewSheetSize.height : .infinity,
            alignment: .topLeading
        )
        .shadow(color: AppColors.paperShadow.opacity(isPreview ? 1 : 0), radius: 24, x: 0, y: 18)
        .animation(.easeInOut(duration: 0.45), value: stage)
    }

    private func saveLetter() {
        isInputFocused = false
        dismissKeyboard()
        isFolded = false
        phaseOneProgress = 0
        phaseTwoProgress = 0
        foldStage = .idle
        isFoldAnimating = false
        isPreviewOverlayVisible = false

        withAnimation(.easeInOut(duration: previewTransitionDuration)) {
            stage = .transitioningToPreview
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + previewOverlayDelay) {
            withAnimation(.easeOut(duration: previewTransitionDuration - previewOverlayDelay)) {
                isPreviewOverlayVisible = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + previewTransitionDuration) {
            withAnimation(.easeInOut(duration: 0.2)) {
                stage = .paperPreview
            }
        }
    }

    private func handleBack() {
        if stage == .editing {
            // Placeholder for navigation pop.
        } else {
            returnToEditing()
        }
    }

    private func returnToEditing() {
        withAnimation(.easeInOut(duration: 0.35)) {
            stage = .editing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isInputFocused = true
        }
    }

    private func toggleFold() {
        guard !isFoldAnimating else { return }
        isFoldAnimating = true

        if isFolded {
            foldStage = .phaseTwo

            withAnimation(.linear(duration: 0.2)) {
                phaseTwoProgress = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                foldStage = .phaseOne

                withAnimation(.linear(duration: 0.2)) {
                    phaseOneProgress = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFolded = false
                    foldStage = .idle
                    isFoldAnimating = false
                }
            }
        } else {
            foldStage = .phaseOne

            withAnimation(.linear(duration: 0.2)) {
                phaseOneProgress = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                foldStage = .phaseTwo

                withAnimation(.linear(duration: 0.2)) {
                    phaseTwoProgress = 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFolded = true
                    foldStage = .folded
                    isFoldAnimating = false
                }
            }
        }
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }

    private var previewOverlayOpacity: Double {
        if stage == .paperPreview {
            return 1
        }

        return isPreviewOverlayVisible ? 1 : 0
    }

    private var topBarForegroundOpacity: Double {
        stage == .editing ? 1 : 0
    }

    private var topBarForegroundBlur: CGFloat {
        stage == .editing ? 0 : 12
    }
}

#Preview {
    ComposeLetterView()
}
