//
//  NoConnectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct NoConnectionView: View {
    let menuName: String
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Image(systemName: "wifi.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .padding()
            Text("연결이 끊어졌습니다.")
                .font(.title2)
            Text("비행기 모드를 끄거나 Wi-Fi에 연결하세요.")
                .foregroundStyle(.gray)
                .padding(.bottom)
            Spacer()
        }
        .padding(.bottom)
        .navigationTitle(menuName)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.clear, for: .navigationBar)
        .customNavigationTitleWithRightIcon {
            ShowSettingsButtonView()
        }
    }
}

#Preview {
    NoConnectionView(menuName: "Home")
}
