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
            }

            // 닫기 버튼
            VStack {
                HStack {
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
                    Spacer()
                }
                Spacer()
            }
        }
        .task { await model.loadInitial(startVideoId: initialVideoId) }
        .onDisappear { model.cleanup() }
    }
}

// MARK: - UIPageViewController 래퍼
struct ShortsPageViewController: UIViewControllerRepresentable {
    @ObservedObject var model: ShortsPlayerModel

    func makeUIViewController(context: Context) -> UIPageViewController {
        let vc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            options: [.interPageSpacing: 0]
        )
        vc.dataSource = context.coordinator
        vc.delegate = context.coordinator
        vc.view.backgroundColor = .black
        return vc
    }

    func updateUIViewController(_ pageVC: UIPageViewController, context: Context) {
        // 첫 페이지만 세팅 (이후는 dataSource가 담당)
        guard pageVC.viewControllers?.isEmpty != false,
              !model.videoIds.isEmpty else { return }
        let initial = makePage(index: 0)
        pageVC.setViewControllers([initial], direction: .forward, animated: false)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makePage(index: Int) -> ShortsPageVC {
        ShortsPageVC(index: index, player: model.player)
    }

    // MARK: Coordinator
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: ShortsPageViewController

        init(parent: ShortsPageViewController) { self.parent = parent }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let page = viewController as? ShortsPageVC,
                  page.index > 0 else { return nil }
            return parent.makePage(index: page.index - 1)
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let page = viewController as? ShortsPageVC,
                  page.index < parent.model.videoIds.count - 1 else { return nil }
            return parent.makePage(index: page.index + 1)
        }

        func pageViewController(
            _ pvc: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let page = pvc.viewControllers?.first as? ShortsPageVC else { return }
            parent.model.onPageChanged(to: page.index)
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
