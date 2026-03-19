//
//  ShortsPlayerModel.swift
//  Atwy
//

import Foundation
import AVKit
import YouTubeKit

@MainActor
class ShortsPlayerModel: ObservableObject {
    @Published var videoIds: [String] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = true

    let player = AVPlayer()

    // 미리 만들어둔 AVPlayerItem 캐시
    private var cachedItems: [String: AVPlayerItem] = [:]
    // AVURLAsset이 사용하는 리소스 로더를 아이템이 살아있는 동안 유지
    private var resourceLoaders: [String: AssetRessourceLoader] = [:]

    private var continuation: String?
    private var isFetchingMore = false

    func loadInitial(startVideoId: String) async {
        isLoading = true
        let (ids, cont) = await ShortsService.shared.fetchShortsFeed()
        continuation = cont

        var finalIds = ids.filter { !$0.isEmpty }

        // 클릭한 숏츠를 맨 앞에 배치
        if !finalIds.contains(startVideoId) {
            finalIds.insert(startVideoId, at: 0)
        } else if let idx = finalIds.firstIndex(of: startVideoId), idx != 0 {
            finalIds.remove(at: idx)
            finalIds.insert(startVideoId, at: 0)
        }

        videoIds = Array(finalIds.prefix(50))
        isLoading = false

        // 첫 영상 재생 + 다음 영상 미리 로드
        await playVideo(at: 0)
        Task.detached { [weak self] in await self?.preload(index: 1) }
    }

    func onPageChanged(to index: Int) {
        guard index != currentIndex else { return }
        currentIndex = index
        Task {
            await playVideo(at: index)
            Task.detached { [weak self] in await self?.preload(index: index + 1) }
            if index >= videoIds.count - 5 { await fetchMore() }
        }
    }

    private func playVideo(at index: Int) async {
        guard index < videoIds.count else { return }
        let videoId = videoIds[index]

        if let cached = cachedItems[videoId] {
            player.replaceCurrentItem(with: cached)
            player.play()
        } else {
            if let item = await makeItem(videoId: videoId) {
                cachedItems[videoId] = item
                player.replaceCurrentItem(with: item)
                player.play()
            }
        }
    }

    private func preload(index: Int) async {
        guard index < videoIds.count else { return }
        let videoId = videoIds[index]
        guard cachedItems[videoId] == nil else { return }
        if let item = await makeItem(videoId: videoId) {
            await MainActor.run { cachedItems[videoId] = item }
        }
    }

    private func fetchMore() async {
        guard !isFetchingMore, let cont = continuation else { return }
        isFetchingMore = true
        let (newIds, newCont) = await ShortsService.shared.fetchContinuation(cont)
        continuation = newCont
        let unique = newIds.filter { !videoIds.contains($0) }
        videoIds.append(contentsOf: unique)
        isFetchingMore = false
    }

    // 스트리밍 URL → AVPlayerItem 생성 (AssetRessourceLoader로 VP9 필터)
    private func makeItem(videoId: String) async -> AVPlayerItem? {
        guard let infos = try? await YTVideo(videoId: videoId).fetchStreamingInfosThrowing(youtubeModel: YTM),
              let url = infos.streamingURL else { return nil }

        var comps = URLComponents(url: url, resolvingAgainstBaseURL: true)
        comps?.scheme = "customloader"
        guard let loaderURL = comps?.url else { return nil }

        let loader = AssetRessourceLoader()
        let asset = AVURLAsset(url: loaderURL)
        asset.resourceLoader.setDelegate(loader, queue: .main)

        // loader를 videoId 키로 유지 (item과 함께 살아있어야 함)
        await MainActor.run { resourceLoaders[videoId] = loader }

        return AVPlayerItem(asset: asset)
    }

    func cleanup() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        cachedItems.removeAll()
        resourceLoaders.removeAll()
    }
}
