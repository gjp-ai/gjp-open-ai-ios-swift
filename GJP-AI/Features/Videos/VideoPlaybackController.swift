import AVFoundation
import Combine
import Foundation
import Photos
import UIKit

@MainActor
final class VideoPlaybackController: ObservableObject {
    @Published private(set) var currentItem: MediaItem?
    @Published private(set) var isPlaying = false
    @Published private(set) var isDownloading = false
    @Published var exportedFileURL: URL?
    @Published var alertMessage: String?

    let player = AVPlayer()

    private var playlist: [MediaItem] = []
    private var endObserver: NSObjectProtocol?
    private var configuredAudioSession = false

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    func play(_ item: MediaItem, in items: [MediaItem]) {
        playlist = items
        currentItem = item
        configureAudioSession()

        guard let url = item.videoURL else {
            alertMessage = "Video URL is not available."
            return
        }

        let playerItem = AVPlayerItem(url: url)
        observeCompletion(of: playerItem)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        isPlaying = true
    }

    func togglePlayback() {
        guard currentItem != nil else { return }
        if isPlaying {
            player.pause()
        } else {
            configureAudioSession()
            player.play()
        }
        isPlaying.toggle()
    }

    func playNext() {
        guard let currentItem,
              let currentIndex = playlist.firstIndex(of: currentItem),
              playlist.indices.contains(currentIndex + 1) else {
            player.pause()
            isPlaying = false
            return
        }
        play(playlist[currentIndex + 1], in: playlist)
    }

    func prepareFileExport(for item: MediaItem) {
        Task {
            do {
                exportedFileURL = try await downloadVideoFile(for: item)
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    func saveToPhotos(_ item: MediaItem) {
        Task {
            do {
                let fileURL = try await downloadVideoFile(for: item)
                try await requestPhotoLibraryAccess()
                try await saveVideoToPhotoLibrary(fileURL)
                alertMessage = "Saved to Photos."
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }

    private func configureAudioSession() {
        guard !configuredAudioSession else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            configuredAudioSession = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func observeCompletion(of playerItem: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let playbackController = self else { return }
            Task { @MainActor in
                playbackController.playNext()
            }
        }
    }

    private func downloadVideoFile(for item: MediaItem) async throws -> URL {
        guard let sourceURL = item.videoURL else {
            throw VideoPlaybackError.missingURL
        }

        isDownloading = true
        defer { isDownloading = false }

        let (temporaryURL, response) = try await URLSession.shared.download(from: sourceURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw VideoPlaybackError.downloadFailed
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(item.downloadFileName)
        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    private func requestPhotoLibraryAccess() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw VideoPlaybackError.photoAccessDenied
        }
    }

    private func saveVideoToPhotoLibrary(_ fileURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}

private enum VideoPlaybackError: LocalizedError {
    case missingURL
    case downloadFailed
    case photoAccessDenied

    var errorDescription: String? {
        switch self {
        case .missingURL:
            "Video URL is not available."
        case .downloadFailed:
            "The video download failed."
        case .photoAccessDenied:
            "Photos access was not granted."
        }
    }
}

private extension MediaItem {
    var videoURL: URL? {
        guard let url else { return nil }
        return URL(string: url)
    }

    var downloadFileName: String {
        let rawName = displayTitle
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = rawName.isEmpty ? id : rawName
        let fileExtension = videoURL?.pathExtension.isEmpty == false ? videoURL?.pathExtension : "mp4"
        return "\(fileName).\(fileExtension ?? "mp4")"
    }
}
