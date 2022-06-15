This project harvests a simple Metal render pipeline and outputs reproduction directions and observations about trying to generate a JSON Pipeline Scripts using `metal-source`.

# Background

The WWDC 2022 session [Target and optimize GPU binaries with Metal 3](https://developer.apple.com/videos/play/wwdc2022/10102/) suggests the `metal-source` tool can generate the JSON Pipeline Scripts.

Using the session's ([5:55](https://developer.apple.com/videos/play/wwdc2022/10102/?time=355)) command line directions:

```json
metal-source -flatbuffers=json harvested-binaryArchive.metallib -o /tmp/descriptors.mtlp-json
```

# Findings

Running this project...

1. Opens a new window (SwiftUI/MTKView) displaying a white square (point primitive).

2. Behind the scenes, a GPU Archive is generated ([MetalRenderer.swift](./x-metal-harvest-gpu-binary/MetalRenderer.swift#L19-23)):
    ```swift
    let archivePath = NSTemporaryDirectory().appending("x-metal-harvested-gpu-binary.metallib")
    let archiveDesc = MTLBinaryArchiveDescriptor()
    let archive = try device.makeBinaryArchive(descriptor: archiveDesc)
    try archive.addRenderPipelineFunctions(descriptor: pipelineDesc)
    try archive.serialize(to: NSURL.fileURL(withPath: archivePath))
    ```
    https://github.com/peterwmwong/x-metal-harvest-gpu-binary/blob/519edd273b016d6c12f0692be4f4af0f00074b35/x-metal-harvest-gpu-binary/MetalRenderer.swift#L19-L23

3. If successful, outputs to console the GPU Archive's path and `metal-source` command to reproduce error and observed error on a MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 22A5266r, Version 14.0 beta 14A5228 environment.
    - Example output:

    ```
    Successfully serialized/harvested GPU Archive! Path: /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib
    In a terminal, attempt the following command to generate the JSON Pipeline Scripts:

    > xcrun metal-source -flatbuffers=json /var/folders/bd/9qd81pgj4xj01bg4sgp43dvr0000gn/T/x-metal-harvested-gpu-binary.metallib -o /tmp/descriptors.mtlp-json

    Notice an error occurs (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 22A5266r, Version 14.0 beta 14A5228 environment):
    metal-source: error: unsupported binary format

    Basic information about harvested GPU archive (based on MacBook Pro 2021 M1 Max, macOS Version 13.0 Beta 22A5266r, Version 14.0 beta 14A5228 environment):
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