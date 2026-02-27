import SwiftUI
import UIKit

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    let isActive: Bool
    let onPlayingChanged: (Bool) -> Void
    let onElapsedChanged: (Int) -> Void
    let onZoomChanged: (Bool) -> Void
    @State private var isZoomed = false
    @State private var zoomResetToken = UUID()
    private let topBarReserve: CGFloat = 70
    private let statsReserve: CGFloat = 66

    init(
        mode: GameMode,
        statsStore: StatsStore,
        isActive: Bool,
        onPlayingChanged: @escaping (Bool) -> Void = { _ in },
        onElapsedChanged: @escaping (Int) -> Void = { _ in },
        onZoomChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: mode, statsStore: statsStore))
        self.isActive = isActive
        self.onPlayingChanged = onPlayingChanged
        self.onElapsedChanged = onElapsedChanged
        self.onZoomChanged = onZoomChanged
    }

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()
            GameBoardView(viewModel: viewModel, isZoomed: $isZoomed, resetToken: zoomResetToken)
                .padding(.horizontal, 12)
                .padding(.top, topBarReserve)
                .padding(.bottom, statsReserve)
                .ignoresSafeArea(edges: [])

            StatsOverlay(mode: viewModel.mode.id)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .frame(maxHeight: .infinity, alignment: .bottomLeading)
                .opacity(isZoomed ? 0.0 : 1.0)
        }
        .alert(viewModel.resultTitle, isPresented: $viewModel.showResult) {
            Button("New Game") {
                viewModel.startNewGame()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
        .onAppear { viewModel.setActive(isActive) }
        .onChange(of: isActive) { value in
            viewModel.setActive(value)
        }
        .onChange(of: viewModel.hasStarted) { value in
            onPlayingChanged(value)
        }
        .onChange(of: viewModel.state.status) { value in
            if value != .playing {
                onPlayingChanged(false)
                zoomResetToken = UUID()
            }
        }
        .onChange(of: viewModel.elapsedSeconds) { value in
            onElapsedChanged(value)
        }
        .onAppear {
            onElapsedChanged(viewModel.elapsedSeconds)
        }
        .onChange(of: isZoomed) { value in
            onZoomChanged(value)
        }
        .onAppear {
            onZoomChanged(isZoomed)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startNewGame)) { notification in
            guard let target = notification.object as? ModePage else { return }
            if target == modePage {
                viewModel.startNewGame()
            }
        }
    }

    private var modePage: ModePage {
        switch viewModel.mode.id {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        case .custom: return .custom
        }
    }
}

struct ElapsedTimeView: View {
    let elapsedSeconds: Int

    var body: some View {
        Text(elapsedString)
            .font(.custom("AvenirNext-DemiBold", size: 14).monospacedDigit())
            .foregroundStyle(Color(red: 0.72, green: 0.12, blue: 0.12))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.98, green: 0.86, blue: 0.86), in: Capsule())
    }

    private var elapsedString: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var isZoomed: Bool
    let resetToken: UUID

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let availableHeight = proxy.size.height
            let rows = viewModel.state.board.rows
            let cols = viewModel.state.board.cols
            let gridSpacing: CGFloat = 2
            let gridPadding: CGFloat = 4
            let widthCell = (availableWidth - (gridPadding * 2) - (gridSpacing * CGFloat(cols - 1))) / CGFloat(cols)
            let heightCell = (availableHeight - (gridPadding * 2) - (gridSpacing * CGFloat(rows - 1))) / CGFloat(rows)
            let rawSize = min(widthCell, heightCell)
            let cellSize = max(12, floor(rawSize))

            let gridWidth = (cellSize * CGFloat(cols)) + (gridSpacing * CGFloat(max(cols - 1, 0))) + (gridPadding * 2)
            let gridHeight = (cellSize * CGFloat(rows)) + (gridSpacing * CGFloat(max(rows - 1, 0))) + (gridPadding * 2)
            let contentSize = CGSize(width: gridWidth, height: gridHeight)

            ZoomableScrollView(
                minZoomScale: 1.0,
                maxZoomScale: 4.0,
                isZoomed: $isZoomed,
                contentSize: contentSize,
                resetToken: resetToken
            ) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: cols), spacing: gridSpacing) {
                    ForEach(viewModel.state.board.cells) { cell in
                        CellView(cell: cell, size: cellSize)
                            .onTapGesture {
                                viewModel.reveal(at: cell.id)
                            }
                            .onLongPressGesture {
                                viewModel.toggleFlag(at: cell.id)
                            }
                    }
                }
                .padding(gridPadding)
                .compositingGroup()
                .drawingGroup()
                .transaction { $0.animation = nil }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct GameBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.95),
                Color(red: 0.93, green: 0.95, blue: 0.97)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let minZoomScale: CGFloat
    let maxZoomScale: CGFloat
    @Binding var isZoomed: Bool
    let contentSize: CGSize
    let resetToken: UUID
    let content: Content

    init(
        minZoomScale: CGFloat,
        maxZoomScale: CGFloat,
        isZoomed: Binding<Bool>,
        contentSize: CGSize,
        resetToken: UUID,
        @ViewBuilder content: () -> Content
    ) {
        self.minZoomScale = minZoomScale
        self.maxZoomScale = maxZoomScale
        _isZoomed = isZoomed
        self.contentSize = contentSize
        self.resetToken = resetToken
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = CenteringScrollView()
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.decelerationRate = .fast
        scrollView.minimumZoomScale = minZoomScale
        scrollView.maximumZoomScale = maxZoomScale
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .clear

        let host = context.coordinator.hostingController
        host.view.backgroundColor = .clear
        host.view.frame = CGRect(origin: .zero, size: contentSize)
        scrollView.addSubview(host.view)
        scrollView.contentSize = contentSize
        scrollView.onLayout = { [weak coordinator = context.coordinator] scrollView in
            coordinator?.updateInsets(scrollView)
            coordinator?.updateZoomBinding(scrollView)
        }
        context.coordinator.updateInsets(scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = AnyView(content)
        if context.coordinator.lastResetToken != resetToken {
            context.coordinator.lastResetToken = resetToken
            scrollView.setZoomScale(minZoomScale, animated: false)
            scrollView.contentOffset = .zero
        }

        if scrollView.minimumZoomScale != minZoomScale {
            scrollView.minimumZoomScale = minZoomScale
        }
        if scrollView.maximumZoomScale != maxZoomScale {
            scrollView.maximumZoomScale = maxZoomScale
        }

        let lastSize = context.coordinator.lastContentSize
        let sizeDelta = abs(lastSize.width - contentSize.width) + abs(lastSize.height - contentSize.height)
        let sizeChanged = sizeDelta > 0.5

        if sizeChanged {
            context.coordinator.lastContentSize = contentSize
            context.coordinator.hostingController.view.frame = CGRect(origin: .zero, size: contentSize)
            scrollView.contentSize = contentSize

            if scrollView.zoomScale <= minZoomScale + 0.01 {
                scrollView.setZoomScale(minZoomScale, animated: false)
                scrollView.contentOffset = .zero
            }
        } else if context.coordinator.hostingController.view.frame.size != contentSize {
            context.coordinator.hostingController.view.frame = CGRect(origin: .zero, size: contentSize)
            scrollView.contentSize = contentSize
        }

        if scrollView.zoomScale < minZoomScale {
            scrollView.setZoomScale(minZoomScale, animated: false)
        }

        context.coordinator.updateInsets(scrollView)
        context.coordinator.updateZoomBinding(scrollView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isZoomed: $isZoomed)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        private let isZoomed: Binding<Bool>
        fileprivate var lastContentSize: CGSize = .zero
        private var lastBoundsSize: CGSize = .zero
        fileprivate var lastResetToken = UUID()

        init(isZoomed: Binding<Bool>) {
            self.isZoomed = isZoomed
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            updateInsets(scrollView)
            updateZoomBinding(scrollView)
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale <= scrollView.minimumZoomScale + 0.02 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
            }
            updateInsets(scrollView)
            updateZoomBinding(scrollView)
        }

        func updateInsets(_ scrollView: UIScrollView) {
            let boundsSize = scrollView.bounds.size
            let contentFrame = hostingController.view.frame
            let scaledContentWidth = contentFrame.size.width
            let scaledContentHeight = contentFrame.size.height

            let horizontalInset = max((boundsSize.width - scaledContentWidth) * 0.5, 0)
            let verticalInset = max((boundsSize.height - scaledContentHeight) * 0.5, 0)
            let newInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
            scrollView.contentInset = newInset

            lastBoundsSize = boundsSize

            if scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 {
                scrollView.contentOffset = CGPoint(x: -horizontalInset, y: -verticalInset)
            }
        }

        func updateZoomBinding(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
        }
    }
}

final class CenteringScrollView: UIScrollView {
    var onLayout: ((UIScrollView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        if isDragging || isDecelerating || isTracking || isZooming {
            return
        }
        onLayout?(self)
    }
}
