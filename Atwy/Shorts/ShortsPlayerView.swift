//
//  ShortsPlayerView.swift
//  Atwy
//

import SwiftUI
import AVKit

// MARK: - 메인 뷰
struct ShortsPlayerView: View {
    let initialVideoId: String
    @StateObject private var model = ShortsPlayerModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if model.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            } else if !model.videoIds.isEmpty {
                ShortsPageViewController(model: model)
                    .ignoresSafeArea()
                    // 닫기 버튼 — overlay로 달아야 하위 제스처 안 막힘
                    .overlay(alignment: .topLeading) {
                        Button {
                            model.cleanup()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.5), in: Circle())
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                    }
            }
        }
        .task { await model.loadInitial(startVideoId: initialVideoId) }
        .onDisappear { model.cleanup() }
    }
}

// MARK: - UIPageViewController 래퍼
struct ShortsPageViewController: UIViewControllerRepresentable {
    let model: ShortsPlayerModel

    func makeUIViewController(context: Context) -> UIPageViewController {
        let vc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: [.interPageSpacing: 0]
        )
        vc.dataSource = context.coordinator
        vc.delegate = context.coordinator
        vc.view.backgroundColor = .black

        // makeUIViewController 시점에 이미 videoIds가 로드돼 있으므로 바로 세팅
        if !model.videoIds.isEmpty {
            vc.setViewControllers([makePage(index: 0)], direction: .forward, animated: false)
        }
        return vc
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        // coordinator model 최신화
        context.coordinator.model = model
        // 아직 초기 VC 없으면 세팅
        if pageVC.viewControllers?.isEmpty != false, !model.videoIds.isEmpty {
            pageVC.setViewControllers([makePage(index: 0)], direction: .forward, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makePage(index: Int) -> ShortsPageVC {
        ShortsPageVC(index: index, player: model.player)
    }

    // MARK: Coordinator
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var model: ShortsPlayerModel  // var: updateUIViewController에서 최신화

        init(model: ShortsPlayerModel) { self.model = model }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let page = viewController as? ShortsPageVC,
                  page.index > 0 else { return nil }
            return ShortsPageVC(index: page.index - 1, player: model.player)
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let page = viewController as? ShortsPageVC,
                  page.index < model.videoIds.count - 1 else { return nil }
            return ShortsPageVC(index: page.index + 1, player: model.player)
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let page = pvc.viewControllers?.first as? ShortsPageVC else { return }
            model.onPageChanged(to: page.index)
        }
    }
}

// MARK: - 개별 Short 페이지
class ShortsPageVC: UIViewController {
    let index: Int
    let player: AVPlayer
    private var playerLayer: AVPlayerLayer?

    init(index: Int, player: AVPlayer) {
        self.index = index
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        self.playerLayer = layer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
}
