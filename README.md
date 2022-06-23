This project demonstrates the `metal-source: error: unsupported binary format` error when trying to use `metal-source` on a harvested GPU archive.

This is associated to FB10274656 (Apple Feedback Assistant).

# Background

The WWDC 2022 session [Target and optimize GPU binaries with Metal 3](https://developer.apple.com/videos/play/wwdc2022/10102/) suggests the `metal-source` tool can generate the JSON Pipeline Scripts.

Using the session's ([5:55](https://developer.apple.com/videos/play/wwdc2022/10102/?time=355)) command line directions:

```sh
> metal-source -flatbuffers=json harvested-binaryArchive.metallib -o /tmp/descriptors.mtlp-json
```

# Findings

Running this project serializes/harvests a GPU archive metallib file for a simple render pipeline.

Using `metal-source` (project outputs specific command/arguments to use) on this metallib produces the error: `metal-source: error: unsupported binary format`.

Here's a brief breakdown on how the GPU archive is created and the console output directions that follows:

1. Opens a new window (SwiftUI/MTKView) displaying a white square (point primitive).
    - Render Pipeline Descriptor ([MetalRenderer.swift](./x-metal-harvest-gpu-binary/MetalRenderer.swift#L14-17))
        ```swift
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = lib.makeFunction(name: "main_vertex")
        pipelineDesc.fragmentFunction = lib.makeFunction(name: "main_fragment")
        pipelineDesc.colorAttachments[0]?.pixelFormat = .bgra8Unorm
        ```
    - Shaders ([Shaders.metal](./x-metal-harvest-gpu-binary/Shaders.metal))
        ```metal
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position  [[position]];
            float point_size [[point_size]];
        };


        [[vertex]]
        VertexOut main_vertex() {
            return {
                .position = float4(0),
                .point_size = 128.0
            };
        }

        [[fragment]]
        half4 main_fragment() {
            return half4(1);
        }
        ```

2. Behind the scenes, a GPU Archive is generated ([MetalRenderer.swift](./x-metal-harvest-gpu-binary/MetalRenderer.swift#L19-23)):
    ```swift
    let archivePath = NSTemporaryDirectory().appending("x-metal-harvested-gpu-binary.metallib")
    let archiveDesc = MTLBinaryArchiveDescriptor()
    let archive = try device.makeBinaryArchive(descriptor: archiveDesc)
    try archive.addRenderPipelineFunctions(descriptor: pipelineDesc)
    try archive.serialize(to: NSURL.fileURL(withPath: archivePath))
    ```

3. If successful, outputs to console the GPU Archive's path and `metal-source` command that reproduces the error
    - Example output:

    ```
    Successfully serialized/harvested GPU Archive! Path: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib
    In a terminal, attempt the following command to generate the JSON Pipeline Scripts:

    > xcrun metal-source -flatbuffers=json /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib -o /tmp/descriptors.mtlp-json

    Notice an error occurs (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 2 22A5286j, Xcode Version 14.0 beta 2 14A5229c environment):
    metal-source: error: unsupported binary format

    Basic information about harvested GPU archive (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 2 22A5286j, Xcode Version 14.0 beta 2 14A5229c environment):
    > xcrun metal-readobj /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib

    File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib
    Format: MetalLib
    Arch: air64
    AddressSize: 64bit

    File: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib
    Format: Mach-O 64-bit Apple GPU
    Arch: agx2
    AddressSize: 64bit
    ```
