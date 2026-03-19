//
//  ShortsService.swift
//  Atwy
//

import Foundation

class ShortsService {
    static let shared = ShortsService()

    private let baseURL = "https://www.youtube.com/youtubei/v1"

    private var contextBody: [String: Any] {
        ["context": [
            "client": [
                "clientName": "WEB",
                "clientVersion": "2.20250101.00.00",
                "hl": "ko",
                "gl": "KR"
            ]
        ]]
    }

    // FEshorts 피드 첫 페이지 가져오기
    func fetchShortsFeed() async -> (videoIds: [String], continuation: String?) {
        var body = contextBody
        body["browseId"] = "FEshorts"
        guard let data = await post(endpoint: "browse", body: body) else { return ([], nil) }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return (extractVideoIds(from: json), extractContinuationToken(from: json))
    }

    // 연속 페이지 가져오기
    func fetchContinuation(_ token: String) async -> (videoIds: [String], continuation: String?) {
        var body = contextBody
        body["continuation"] = token
        guard let data = await post(endpoint: "browse", body: body) else { return ([], nil) }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return (extractVideoIds(from: json), extractContinuationToken(from: json))
    }

    private func post(endpoint: String, body: [String: Any]) async -> Data? {
        guard let url = URL(string: "\(baseURL)/\(endpoint)"),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-YouTube-Client-Name")
        request.setValue("2.20250101.00.00", forHTTPHeaderField: "X-YouTube-Client-Version")
        return try? await URLSession.shared.data(for: request).0
    }

    // JSON 재귀 탐색으로 videoId 추출
    // - shortsLockupViewModel (2024.10+ 신규): onTap.innertubeCommand.reelWatchEndpoint.videoId
    // - reelItemRenderer (구버전): videoId
    private func extractVideoIds(from json: Any) -> [String] {
        var ids: [String] = []
        if let dict = json as? [String: Any] {
            // 신규 구조: shortsLockupViewModel
            if let vm = dict["shortsLockupViewModel"] as? [String: Any],
               let onTap = vm["onTap"] as? [String: Any],
               let cmd = onTap["innertubeCommand"] as? [String: Any],
               let reel = cmd["reelWatchEndpoint"] as? [String: Any],
               let videoId = reel["videoId"] as? String {
                ids.append(videoId)
            }
            // 구버전 구조: reelItemRenderer
            if let renderer = dict["reelItemRenderer"] as? [String: Any],
               let videoId = renderer["videoId"] as? String {
                ids.append(videoId)
            }
            for (_, value) in dict {
                ids.append(contentsOf: extractVideoIds(from: value))
            }
        } else if let array = json as? [Any] {
            for item in array { ids.append(contentsOf: extractVideoIds(from: item)) }
        }
        return ids
    }

    // continuation 토큰 재귀 탐색
    private func extractContinuationToken(from json: Any) -> String? {
        if let dict = json as? [String: Any] {
            if let cmd = dict["continuationCommand"] as? [String: Any],
               let token = cmd["token"] as? String { return token }
            for (_, value) in dict {
                if let t = extractContinuationToken(from: value) { return t }
            }
        } else if let array = json as? [Any] {
            for item in array {
                if let t = extractContinuationToken(from: item) { return t }
            }
        }
        return nil
    }
}
