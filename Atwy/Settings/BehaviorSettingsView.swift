//
//  BehaviorSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.01.2024.
//

import SwiftUI

struct BehaviorSettingsView: View {
    var body: some View {
        SettingsMenu(title: "동작") { geometry in
            SettingsSection(title: "성능 모드") {
                Setting(textDescription: "Enabling the limited performance mode will use less CPU and RAM while using the app. It will use other UI components that could make your experience a bit more laggy if the app was working smoothly before but it could make it more smooth if the app was very laggy before.", action: try! SAToggle(PSMType: .performanceModeEnabled, title: "", toggleStyle: PerformanceModeToggleStyle(geometry: geometry)))
            }
            SettingsSection(title: "라이브 활동", settings: {
                Setting(textDescription: "Enabling Live Activities will show a Live Activity giving informations on the current downloadings.", action: try! SAToggle(PSMType: .liveActivitiesEnabled, title: "라이브 활동").setAction { newValue in
                    if #available(iOS 16.1, *) {
                        if PreferencesStorageModel.shared.liveActivitiesEnabled, !newValue {
                            LiveActivitesManager.shared.removeAllActivities()
                        } else if !PreferencesStorageModel.shared.liveActivitiesEnabled, newValue, DownloadersModel.shared.activeDownloaders.count != 0 {
                            for downloader in DownloadersModel.shared.activeDownloaders {
                                let activity = DownloaderProgressActivity(downloader: downloader)
                                activity.setupOnManager(attributes: .init(), state: activity.getNewData())
                            }
                        }
                    }
                    return newValue
                })
            }, hidden: {if #available(iOS 16.1, *) { false } else { true }}())
            SettingsSection(title: "다운로드") {
                Setting(textDescription: nil, action: try! SAStepper(valueType: Int.self, PSMType: .concurrentDownloadsLimit, title: "동시 다운로드 제한").setAction { let newValue = max(1, $0); DownloadersModel.shared.maxConcurrentDownloadsChanged(newValue); return newValue })
            }
            SettingsSection(title: "화면 속 화면") {
                Setting(textDescription: "Enabling automatic Picture in Picture (PiP) will switch to PiP when put the app in background but don't quit it, while playing a video. If the player is playing an audio-only asset the PiP will never launch.", action: try! SAToggle(PSMType: .automaticPiP, title: "자동 PiP"))
            }
            SettingsSection(title: "백그라운드 재생") {
                Setting(textDescription: "Enabling background playback will make the player continue playing the video/audio when you quit the app or shut down the screen. If automatic PiP is enabled, it will be preferred over simple background playback when quitting the app.", action: try! SAToggle(PSMType: .backgroundPlayback, title: "백그라운드 재생"))
            }
            SettingsSection(title: "자동 전체화면") {
                Setting(textDescription: "Enabling automatic fullscreen makes the player enter fullscreen whenever you switch to a landscape orientation or exit it when you switch to a portrait mode.", action: try! SAToggle(PSMType: .automaticFullscreen, title: "자동 전체화면"))
            }
        }
    }
}
