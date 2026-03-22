import SwiftUI

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
    @FocusState private var isInputFocused: Bool
    private let previewSheetSize = CGSize(width: 332, height: 476)

    var body: some View {
        ZStack {
            AppColors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if stage == .editing {
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                contentView
            }
            .animation(.easeInOut(duration: 0.4), value: stage)
        }
        .onAppear {
            isInputFocused = true
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                // Placeholder for navigation pop.
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Text(draft.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(1)

            Spacer()

            Button {
                saveLetter()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accentYellow)
            .clipShape(Circle())
        }
        .padding(.horizontal, 10)
        .padding(.top, AppSpacing.topBar)
        .padding(.bottom, 20)
    }

    private var contentView: some View {
        VStack(spacing: 24) {
            if stage == .paperPreview {
                Spacer(minLength: 16)
            }

            letterContainer

            if stage == .paperPreview {
                Button(isFolded ? "Развернуть" : "Свернуть") {
                    toggleFold()
                }
                .font(.system(size: 17, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accentYellow)
                .foregroundStyle(.black)
                .disabled(isFoldAnimating)
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.horizontal)
    }

    private var letterContainer: some View {
        let isPreview = stage == .paperPreview

        return ZStack(alignment: .topLeading) {
            if isPreview {
                PaperSheetView(
                    text: draft.body,
                    phaseOneProgress: phaseOneProgress,
                    phaseTwoProgress: phaseTwoProgress,
                    foldStage: foldStage
                )
                    .allowsHitTesting(false)
            } else {
                ZStack(alignment: .topLeading) {
                    editorVisualText

                    TextEditor(text: $draft.body)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.clear)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .focused($isInputFocused)
                        .padding(.horizontal, 13)
                        .padding(.top, 8)
                }
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

    private var editorVisualText: some View {
        Text(draft.body.isEmpty ? " " : draft.body)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.black)
            .lineSpacing(3)
            .padding(.horizontal, 18)
            .padding(.top, 16)
    }

    private func saveLetter() {
        isInputFocused = false
        isFolded = false
        phaseOneProgress = 0
        phaseTwoProgress = 0
        foldStage = .idle
        isFoldAnimating = false

        withAnimation(.easeInOut(duration: 0.45)) {
            stage = .paperPreview
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
}

#Preview {
    ComposeLetterView()
}
