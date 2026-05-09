import SwiftUI

struct QuestionRow: View {
    let question: Question

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                SafeHTMLText(html: question.answer)
                    .textSelection(.enabled)
                TagFlow(tags: question.tags)
            }
            .padding(.vertical, 8)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text("Q")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.tint, in: Circle())
                Text(question.question)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
