import SwiftUI
import Combine

@MainActor
final class SplashModel: ObservableObject {
    @Published var error: String?
    @Published var isInitializing = false
    
    private let app: AppModel
    private var refreshTask: Task<Void, Never>?
    
    init(app: AppModel) {
        self.app = app
    }
    
    func initialize(onComplete: @escaping () -> Void) async {
        guard !isInitializing else { return }
        isInitializing = true
        error = nil
        
        // Requirement: 3-second timeout logic
        // 1. Try to refresh settings
        // 2. If it takes > 3s and we have cache, proceed
        // 3. If it fails and we have cache, proceed
        // 4. If no cache and fails/timeouts, show error
        
        refreshTask = Task {
            await app.refreshSettings()
        }
        
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            return true
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [refreshTask] in await refreshTask?.value }
            group.addTask {
                if await timeoutTask.value {
                    // Timeout reached. If we have cache, we can finish.
                    if await !self.app.settings.isEmpty {
                        await self.refreshTask?.cancel()
                    }
                }
            }
            // Wait for first completion
            _ = await group.next()
            group.cancelAll()
        }
        
        isInitializing = false
        
        if !app.settings.isEmpty {
            onComplete()
        } else {
            error = app.settingsError ?? L10n.text("failed", app.language)
        }
    }
    
    func cancel() {
        refreshTask?.cancel()
        refreshTask = nil
        isInitializing = false
    }
}
