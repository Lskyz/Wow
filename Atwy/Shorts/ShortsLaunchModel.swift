//
//  ShortsLaunchModel.swift
//  Atwy
//

import Foundation

class ShortsLaunchModel: ObservableObject {
    static let shared = ShortsLaunchModel()

    @Published var isPresented: Bool = false
    private(set) var initialVideoId: String = ""

    func present(videoId: String) {
        initialVideoId = videoId
        isPresented = true
    }
}
