//
//  YouTubeModel+getVisitorData.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.02.2025.
//  Copyright © 2025-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import YouTubeKit
import OSLog

extension YouTubeModel {
    func getVisitorData() async {
        let oldVisitorData = YTM.visitorData
        YTM.visitorData = ""
        // 캐시 제거 후 매번 새 세션 요청
        URLCache.shared.removeAllCachedResponses()
        let randomQuery = UUID().uuidString.prefix(8)
        if let visitorData = try? await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: String(randomQuery)]).visitorData {
            YTM.visitorData = visitorData
        } else if let visitorData = try? await SearchResponse.sendThrowingRequest(youtubeModel: YTM, data: [.query: "mrbeast"]).visitorData {
            YTM.visitorData = visitorData
        } else {
            YTM.visitorData = oldVisitorData
            Logger.atwyLogs.simpleLog("Couldn't get visitorData, request may fail.")
        }
    }
}
