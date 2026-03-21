import SwiftUI

struct PaperSheetView: View {
    let text: String
    @Binding var isFolded: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.paperFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppColors.paperBorder, lineWidth: 1)
                )

            Text(text.isEmpty ? " " : text)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black)
                .lineSpacing(3)
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .compositingGroup()
        .scaleEffect(x: 1, y: isFolded ? 0.52 : 1, anchor: .center)
        .overlay(alignment: .center) {
            if isFolded {
                Rectangle()
                    .fill(.black.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 10)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: isFolded)
    }
}
