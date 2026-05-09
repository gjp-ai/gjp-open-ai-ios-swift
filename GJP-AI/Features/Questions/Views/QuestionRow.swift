import SwiftUI

struct QuestionRow: View {
    let question: Question

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("A")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.green.gradient, in: Circle())
                    SafeHTMLText(html: question.answer)
                        .textSelection(.enabled)
                }
                TagFlow(tags: question.tags)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("Q")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.gradient, in: Circle())
                Text(question.question)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
