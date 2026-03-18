//
//  SettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.11.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import SwiftUI
import Security
import AVKit

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NPM = NavigationPathModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    @State private var showingConfirmation: Bool = false
    @State private var showInstructions: Bool = true
    var body: some View {
        NavigationStack(path: $NPM.settingsSheetPath) {
            ScrollView {
                VStack {
                    if !NM.connected {
                        VStack(alignment: .center) {
                            Image(systemName: "wifi.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .padding(.top)
                            Text("연결이 끊어졌습니다.")
                                .font(.caption)
                            Text("계정 설정을 보려면 비행기 모드를 끄거나 Wi-Fi에 연결하세요.")
                                .foregroundStyle(.gray)
                                .font(.caption2)
                        }
                    } else if let account = APIM.userAccount, account.name != nil {
                        UserPreferenceCircleView()
                            .frame(width: 100, height: 100)
                            .padding(.top)
                        VStack {
                            Text(account.name ?? "")
                                .font(.title2)
                                .bold()
                            Text(account.channelHandle ?? "")
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text("계정 연결 해제")
                                Image(systemName: "minus.circle")
                                    .frame(width: 30, height: 30)
                            }
                            .foregroundColor(.red)
                            .onTapGesture {
                                showingConfirmation = true
                            }
                            .confirmationDialog("계정 연결 해제?", isPresented: $showingConfirmation) {
                                Button("예", role: .destructive) {
                                    APIM.deleteAccount()
                                }
                                Button("취소", role: .cancel) { }
                            } message: {
                                Text("연결 해제 확인")
                            }
                            .padding(.top)
                        }
                    } else if APIM.isFetchingAccountInfos {
                        LoadingView(customText: "account infos")
                    } else {
                        VStack {
                            HStack {
                                Text("YouTube 계정 연결")
                                Image(systemName: "plus.circle")
                                    .frame(width: 30, height: 30)
                            }
                            .routeTo(.googleConnection)
                        }
                        .padding()
                    }
                    List {
                        SettingsEntry(
                            iconName: "doc.questionmark.fill",
                            iconColor: .white,
                            iconBackgroundColor: .green,
                            title: "동작",
                            routeTo: .behaviorSettings)
                        SettingsEntry(
                            iconName: "textformat.size",
                            iconColor: .white,
                            iconBackgroundColor: .blue,
                            title: "외관",
                            routeTo: .appearanceSettings)
                        SettingsEntry(
                            iconName: "gear",
                            iconColor: .white,
                            iconBackgroundColor: .gray,
                            title: "저장소",
                            routeTo: .storageSettings)
                        SettingsEntry(
                            iconName: "list.bullet.rectangle",
                            iconColor: .black,
                            iconBackgroundColor: .yellow,
                            title: "콘솔",
                            routeTo: .consoleSettings)
                        SettingsEntry(
                            iconName: "list.bullet.clipboard",
                            iconColor: .white,
                            iconBackgroundColor: .red,
                            title: "YouTubeKit 로거",
                            routeTo: .loggerSettings)
                        SettingsEntry(
                            iconName: "exclamationmark.triangle.fill",
                            iconColor: .yellow,
                            iconBackgroundColor: .black,
                            title: "비공개 API",
                            routeTo: .privateAPIsSettings)
                        SettingsEntry(
                            iconName: "book.fill",
                            iconColor: .white,
                            iconBackgroundColor: .orange,
                            title: "라이선스",
                            routeTo: .licensesSettings)
                    }
                    .frame(height: 360)
                }
            }
            .routeContainer()
            .navigationTitle("설정")
            #if os(macOS)
            .toolbar(content: {
                ToolbarItem(placement: .secondaryAction, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("확인")
                            .bold()
                    }
                })
            })
            #else
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button {
                        dismiss()
                    } label: {
                        Text("확인")
                            .bold()
                    }
                })
            })
            #endif
        }
    }
}

#Preview {
    SettingsView()
}
