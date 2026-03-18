//
//  DownloadingItemsContextMenuView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 28.01.23.
//  Copyright © 2023-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct DownloadingItemsContextMenuView: View {
    @StateObject var downloader: HLSDownloader
    var body: some View {
        if downloader.downloadTask?.state == .suspended {
            Button {
                downloader.resumeDownload()
                PopupsModel.shared.showPopup(.resumedDownload, data: downloader.downloadInfo.thumbnailData)
            } label: {
                HStack {
                    Text("다운로드 재개")
                    Image(systemName: "play")
                }
            }
        } else if downloader.downloadTask?.state == .running {
            Button {
                downloader.pauseDownload()
                PopupsModel.shared.showPopup(.pausedDownload, data: downloader.downloadInfo.thumbnailData)
            } label: {
                HStack {
                    Text("다운로드 일시정지")
                    Image(systemName: "pause")
                }
            }
        }
        Button(role: .destructive) {
            DownloadersModel.shared.cancelDownloadFor(downloader: downloader)
        } label: {
            HStack {
                Text("다운로드 취소")
                Image(systemName: "multiply")
            }
        }
    }
}
