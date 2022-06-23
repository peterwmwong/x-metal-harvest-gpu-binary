import SwiftUI
import Metal

struct MetalRenderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState

    public init(device: MTLDevice) throws {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        let lib = device.makeDefaultLibrary()!
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = lib.makeFunction(name: "main_vertex")
        pipelineDesc.fragmentFunction = lib.makeFunction(name: "main_fragment")
        pipelineDesc.colorAttachments[0]?.pixelFormat = .bgra8Unorm

        let archivePath = NSTemporaryDirectory().appending("x-metal-harvested-gpu-binary.metallib")
        let archiveDesc = MTLBinaryArchiveDescriptor()
        let archive = try device.makeBinaryArchive(descriptor: archiveDesc)
        try archive.addRenderPipelineFunctions(descriptor: pipelineDesc)
        try archive.serialize(to: NSURL.fileURL(withPath: archivePath))
        print("""


Successfully serialized/harvested GPU Archive! Path: \(archivePath)
In a terminal, attempt the following command to generate the JSON Pipeline Scripts:

  > xcrun metal-source -flatbuffers=json \(archivePath) -o /tmp/descriptors.mtlp-json

Notice an error occurs (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 2 22A5286j, Xcode Version 14.0 beta 2 14A5229c environment):
  metal-source: error: unsupported binary format

Basic information about harvested GPU archive (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 2 22A5286j, Xcode Version 14.0 beta 2 14A5229c environment):
  > xcrun metal-readobj \(archivePath)

  File: \(archivePath)
  Format: MetalLib
  Arch: air64
  AddressSize: 64bit

  File: \(archivePath)
  Format: Mach-O 64-bit Apple GPU
  Arch: agx2
  AddressSize: 64bit


""")
        self.renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDesc)
    }

    public func encodeRender(target: MTLTexture, desc: MTLRenderPassDescriptor) -> MTLCommandBuffer {
        let commandBuffer = commandQueue.makeCommandBufferWithUnretainedReferences()!
        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
        enc.setRenderPipelineState(renderPipeline)
        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: 1)
        enc.endEncoding()
        return commandBuffer
    }
}
