//
//  GoogleConnectionView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//  Copyright © 2023-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import SwiftUI

struct GoogleConnectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showInstructions: Bool = true
    var body: some View {
        if showInstructions {
            VStack {
                HStack(alignment: .top) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("안내")
                        .font(.title)
                        .bold()
                    Text("1. Google 계정에 로그인하세요.")
                        .padding(.vertical)
                        .bold()
                    Text("2. ✓ 버튼을 누르세요.")
                        .bold()
                    Text("참고: YouTube에 로그인되어 있지만 ✓ 버튼이 작동하지 않는 경우, ↻ 버튼으로 브라우저를 초기화하고 다시 연결해 보세요.")
                        .font(.caption)
                        .padding(.top)
                }
                .padding()
                Spacer()
                Button {
                    withAnimation {
                        showInstructions = false
                    }
                } label: {
                    Text("연결")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        } else {
            VStack {
                #if !os(macOS)
                WebViewUI()
                    .toolbar {
                        Button {
                            NotificationCenter.default.post(name: .atwyResetCookies, object: nil)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            NotificationCenter.default.post(name: .atwyGetCookies, object: nil)
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                #endif
            }
        }
    }
}
