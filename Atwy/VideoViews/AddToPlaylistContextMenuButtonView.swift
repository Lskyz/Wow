//
//  AddToPlaylistContextMenuButtonView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 10.02.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import YouTubeKit

struct AddToPlaylistContextMenuButtonView: View {
    let video: YTVideo
    var body: some View {
        Button {
            SheetsModel.shared.showSheet(.addToPlaylist, data: video)
        } label: {
            HStack {
                Text("재생목록에 추가")
                Image(systemName: "plus.circle")
            }
        }
    }
}
