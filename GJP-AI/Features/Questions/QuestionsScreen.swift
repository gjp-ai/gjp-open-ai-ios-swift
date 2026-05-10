import SwiftUI

struct QuestionsScreen: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var viewModel: OpenListViewModel<Question>

    init(api: OpenAPIClient = OpenAPIClient()) {
        _viewModel = StateObject(wrappedValue: OpenListViewModel(cacheKey: "questions") { updatedAfter in
            try await api.allQuestions(updatedAfter: updatedAfter)
        })
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(L10n.text("questions", app.language))
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: L10n.text("search", app.language))
                .safeAreaInset(edge: .top) {
                    FilterBar(tags: app.tags("question_tags"), selectedTag: $viewModel.selectedTag, sortOrder: $viewModel.sortOrder)
                        .background(.bar)
                }
        }
        .task(id: app.language) { await viewModel.load(language: app.language) }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView(L10n.text("loading", app.language))
        case .empty:
            ContentUnavailableView(L10n.text("empty", app.language), systemImage: "questionmark.circle")
        case let .error(message):
            ContentUnavailableView(L10n.text("failed", app.language), systemImage: "exclamationmark.triangle", description: Text(message))
        case .content:
            List(viewModel.items) { question in
                OpenCard {
                    QuestionRow(question: question)
                }
                .openListCardRow()
                if question.id == viewModel.items.last?.id, viewModel.canLoadMore {
                    LoadMoreButton(isLoading: viewModel.isLoadingMore) {
                        Task { await viewModel.loadMore() }
                    }
                    .openListCardRow()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .refreshable { await viewModel.refresh() }
        }
    }
}
