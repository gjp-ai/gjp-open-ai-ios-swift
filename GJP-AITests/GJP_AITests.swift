import Foundation
import Testing
@testable import GJP_AI

struct GJP_AITests {
    @Test func apiClientAddsChannelToAllRequests() async throws {
        let session = MockSession(payload: """
        {"status":{"code":200,"message":"OK","errors":null},"data":[]}
        """)
        let client = OpenAPIClient(baseURL: URL(string: "https://example.com/api/open/")!, session: session)

        _ = try await client.appSettings()

        let query = try #require(URLComponents(url: session.lastURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains(URLQueryItem(name: "channel", value: "AI")))
    }

    @Test func apiClientPreservesListFiltersWithChannel() async throws {
        let session = MockSession(payload: """
        {"status":{"code":200,"message":"OK","errors":null},"data":[]}
        """)
        let client = OpenAPIClient(baseURL: URL(string: "https://example.com/api/open/")!, session: session)

        _ = try await client.allWebsites(updatedAfter: "2026-05-24T12:00:00")

        let query = try #require(URLComponents(url: session.lastURL, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains(URLQueryItem(name: "channel", value: "AI")))
        #expect(query.contains(URLQueryItem(name: "isActive", value: "true")))
        #expect(query.contains(URLQueryItem(name: "updatedAfter", value: "2026-05-24T12:00:00")))
    }

    @Test func listViewModelFiltersAndSortsLocally() async throws {
        let model = await OpenListViewModel<Website>(pageSize: 10) { _, _, _, _, _ in
            PagedData(
                content: [
                    Website(id: "2", name: "Beta", url: nil, logoUrl: nil, description: "Second", tags: "AI,Tools", lang: .en, displayOrder: 2, updatedAt: "2026-05-02"),
                    Website(id: "1", name: "Alpha", url: nil, logoUrl: nil, description: "First", tags: "News", lang: .en, displayOrder: 1, updatedAt: "2026-05-01")
                ],
                page: 0,
                size: 10,
                totalElements: 2,
                totalPages: 1
            )
        }

        await model.load(language: .en)
        await MainActor.run {
            model.searchText = "beta"
            model.sortOrder = .alpha
            #expect(model.items.map(\.id) == ["2"])
        }
    }
}

private final class MockSession: HTTPSession {
    var lastURL: URL!
    let payload: String

    init(payload: String) {
        self.payload = payload
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        lastURL = url
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(payload.utf8), response)
    }
}
