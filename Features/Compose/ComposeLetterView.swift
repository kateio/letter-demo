import SwiftUI

struct ComposeLetterView: View {
    @State private var stage: ComposeStage = .editing
    @State private var draft = LetterDraft()
    @State private var isFolded = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            AppColors.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if stage == .editing {
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if stage == .editing {
                    editorStateView
                        .transition(.opacity)
                } else {
                    previewStateView
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
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
        .padding(.horizontal, AppSpacing.horizontal)
        .padding(.top, AppSpacing.topBar)
        .padding(.bottom, 20)
    }

    private var editorStateView: some View {
        TextEditor(text: $draft.body)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(.black)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .focused($isInputFocused)
            .padding(.horizontal, AppSpacing.horizontal + 2)
            .padding(.top, AppSpacing.bodyTop - 2)
            .onTapGesture {
                isInputFocused = true
            }
    }

    private var previewStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)

            PaperSheetView(text: draft.body, isFolded: $isFolded)
                .frame(width: 300, height: 420)
                .shadow(color: AppColors.paperShadow, radius: 24, x: 0, y: 18)

            Button(isFolded ? "Развернуть" : "Свернуть") {
                withAnimation(.easeInOut(duration: 0.45)) {
                    isFolded.toggle()
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .buttonStyle(.borderedProminent)
            .tint(AppColors.accentYellow)
            .foregroundStyle(.black)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.horizontal)
    }

    private func saveLetter() {
        isInputFocused = false

        withAnimation(.easeInOut(duration: 0.45)) {
            stage = .paperPreview
        }
    }
}

#Preview {
    ComposeLetterView()
}
