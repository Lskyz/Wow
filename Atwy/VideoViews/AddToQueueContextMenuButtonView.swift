//
//  AddToQueueContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToQueueContextMenuButtonView: View {
    let video: YTVideo
    let videoThumbnailData: Data?
    var body: some View {
        Button {
            if let videoThumbnailData = videoThumbnailData {
                VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
            }
            VideoPlayerModel.shared.addVideoToTopQueue(video: video)
            PopupsModel.shared.showPopup(.playNext, data: videoThumbnailData)
        } label: {
            HStack {
                Text("다음에 재생")
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
            }
        }
        Button {
            if let videoThumbnailData = videoThumbnailData {
                VideoThumbnailsManager.main.images[video.videoId] = videoThumbnailData
            }
            VideoPlayerModel.shared.addVideoToBottomQueue(video: video)
            PopupsModel.shared.showPopup(.playLater, data: videoThumbnailData)
        } label: {
            HStack {
                Text("나중에 재생")
                Image(systemName: "text.line.last.and.arrowtriangle.forward")
            }
        }
    }
}
