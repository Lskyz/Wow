//
//  PrivateAPIsSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 08.04.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI

struct PrivateAPIsSettingsView: View {
    var body: some View {
        SettingsMenu(title: "Private APIs") { _ in
            VStack(alignment: .leading) {
                Text("경고")
                    .foregroundStyle(.red)
                Text("비공개 API를 활성화하면 기기가 예기치 않게 충돌할 수 있습니다. 충돌 보고서를 제출하기 전에 활성화된 비공개 API를 비활성화하세요.")
            }
            .listRowBackground(Color.red.opacity(0.2))
        } sections: { _ in
            SettingsSection(title: "동영상 플레이어") {
                Setting(
                    textDescription: "Enabling Custom Player Buttons will show various actions such as like/dislike to the video player full-screen view.",
                    action: try! SAToggle(
                        PSMType: .customAVButtonsEnabled,
                        title: "커스텀 플레이어 버튼"
                    )
                    .getAction { returnValue in
                        if PrivateManager.shared.avButtonsManager == nil {
                            return false
                        } else {
                            return returnValue
                        }
                    }
                        .setAction { newValue in
                            guard PrivateManager.shared.avButtonsManager != nil else { return false }
                            if newValue {
                                PrivateManager.shared.avButtonsManager?.inject()
                            } else {
                                PrivateManager.shared.avButtonsManager?.removeInjection()
                            }
                            return newValue
                        }
                    ,
                    privateAPIWarning: PrivateManager.shared.avButtonsManager == nil
                )
            }
            SettingsSection(title: "가변 블러") {
                Setting(
                    textDescription: "Enabling Variable Blur enhances the experience in various UI elements of Atwy such as the Video Player.",
                    action: try! SAToggle(
                        PSMType: .variableBlurEnabled,
                        title: "가변 블러")
                    .getAction { returnValue in
                        if PrivateManager.shared.isVariableBlurAvailable {
                            return returnValue
                        } else {
                            return false
                        }
                    }
                        .setAction { newValue in
                            guard PrivateManager.shared.isVariableBlurAvailable else { return false }
                            DispatchQueue.main.async {
                                PreferencesStorageModel.shared.setNewValueForKey(.variableBlurEnabled, value: newValue)
                            }
                            
                            return newValue
                        },
                    privateAPIWarning: !PrivateManager.shared.isVariableBlurAvailable
                )
            }
            SettingsSection(title: "검색 메뉴") {
                Setting(
                    textDescription: "Enabling Custom Search Menu brings a great search experience to the app. **Changing this option might require to restart the app in order for it to work.**",
                    action: try! SAToggle(
                        PSMType: .customSearchBarEnabled,
                        title: "커스텀 검색 메뉴"
                    )
                    .getAction { returnValue in
                        if PrivateManager.shared.isCustomSearchMenuAvailable {
                            return returnValue
                        } else {
                            return false
                        }
                    }
                        .setAction { newValue in
                            guard PrivateManager.shared.isCustomSearchMenuAvailable else { return false }
                            DispatchQueue.main.async {
                                PreferencesStorageModel.shared.setNewValueForKey(.customSearchBarEnabled, value: newValue)
                            }
                            
                            return newValue
                        }
                    ,
                    privateAPIWarning: !PrivateManager.shared.isVariableBlurAvailable
                )
                Setting(textDescription: "Resetting the Search Textfield Location might help fix the transition to the Search Menu if it's broken.", action: SATextButton(title: "검색창 위치 초기화", buttonLabel: "Reset", action: { _ in
                    PreferencesStorageModel.shared.setNewValueForKey(.searchBarHeight, value: nil)
                    TopSearchBarController.searchBarHeight = nil
                }), privateAPIWarning: !PrivateManager.shared.isCustomSearchMenuAvailable)
            }
        }
    }
}

#Preview {
    PrivateAPIsSettingsView()
}
