import SwiftUI
import MetalKit

final class PreviewMetalView: MTKView {
    private let renderer: MetalRenderer
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.renderer = try! MetalRenderer(device: device)
        super.init(frame: .zero, device: device)
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.autoResizeDrawable = true
        self.framebufferOnly = true
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    override func draw(_ rect: CGRect) {
        if let drawable = currentDrawable {
            let commandBuffer = renderer.encodeRender(target: drawable.texture, desc: currentRenderPassDescriptor!)
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private struct ContentView: NSViewRepresentable {
    func makeNSView(context: Context) -> PreviewMetalView { PreviewMetalView() }
    func updateNSView(_ view: PreviewMetalView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}


@main
struct x_metal_harvest_gpu_binaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
