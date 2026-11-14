import SwiftUI
import MetalKit

/// Декоративный анимированный Metal-фон. Используется ТОЛЬКО на экране приветствия.
///
/// В отличие от оригинала Sorta (который падал в `fatalError`, если library/pipeline
/// не собрались), здесь любой сбой даёт `isReady == false` и пустой кадр - вызывающая
/// сторона показывает статичный тёмный фон. Это защищает и продакшен (старый/виртуальный
/// GPU), и SwiftUI Preview (где `default.metallib` может не найтись в бандле превью).
struct GlowMetalView: NSViewRepresentable {
    /// Управление паузой рендера снаружи (onDisappear / неактивное окно).
    let isPaused: Bool
    /// Светлая тема: пастельная палитра + светлый clearColor вместо тёмного неона.
    let isLight: Bool
    /// Ограничение FPS: фон декоративный, 30 fps достаточно.
    var preferredFPS: Int = 30

    /// clearColor под активную тему (чтобы кадры до первого draw не моргали).
    private var clearColor: MTLClearColor {
        isLight
            ? MTLClearColor(red: 0.9333, green: 0.9412, blue: 0.9647, alpha: 1.0)  // #EEF0F6
            : MTLClearColor(red: 0.0510, green: 0.0510, blue: 0.0784, alpha: 1.0)  // #0D0D14
    }

    /// Доступен ли Metal на этой машине. Вызывающая сторона решает,
    /// показывать Metal-фон или статичный градиент.
    static var isMetalAvailable: Bool {
        MTLCreateSystemDefaultDevice() != nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let metalView = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            context.coordinator.isReady = false
            return metalView
        }

        metalView.device = device
        metalView.delegate = context.coordinator
        metalView.enableSetNeedsDisplay = false
        metalView.framebufferOnly = false
        metalView.clearColor = clearColor
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.preferredFramesPerSecond = preferredFPS

        context.coordinator.isLight = isLight
        context.coordinator.isReady = context.coordinator.setup(device: device)
        // Если pipeline не собрался - паузим, чтобы не дёргать GPU впустую.
        metalView.isPaused = isPaused || !context.coordinator.isReady
        return metalView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.isLight = isLight
        nsView.clearColor = clearColor
        nsView.preferredFramesPerSecond = preferredFPS
        nsView.isPaused = isPaused || !context.coordinator.isReady
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        private var commandQueue: MTLCommandQueue?
        private var pipelineState: MTLRenderPipelineState?
        private var vertexBuffer: MTLBuffer?
        private let startTime = CFAbsoluteTimeGetCurrent()

        /// true только если device + library + pipeline собраны успешно.
        var isReady = false

        /// Светлая тема - шейдер рисует пастельную палитру.
        var isLight = false

        struct Vertex {
            var position: SIMD2<Float>
            var texCoord: SIMD2<Float>
        }

        struct Uniforms {
            var time: Float
            var resolution: SIMD2<Float>
            var glowPosition: SIMD2<Float>
            var isLight: Float
        }

        /// Возвращает false вместо fatalError - нет library/pipeline => fallback на градиент.
        func setup(device: MTLDevice) -> Bool {
            guard let queue = device.makeCommandQueue() else { return false }
            commandQueue = queue

            let vertices: [Vertex] = [
                Vertex(position: SIMD2<Float>(-1, -1), texCoord: SIMD2<Float>(0, 1)),
                Vertex(position: SIMD2<Float>( 1, -1), texCoord: SIMD2<Float>(1, 1)),
                Vertex(position: SIMD2<Float>(-1,  1), texCoord: SIMD2<Float>(0, 0)),
                Vertex(position: SIMD2<Float>( 1,  1), texCoord: SIMD2<Float>(1, 0))
            ]
            vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<Vertex>.stride,
                options: []
            )

            // makeDefaultLibrary -> default.metallib из main bundle.
            // nil => .metal не в Compile Sources ИЛИ превью без бандла.
            guard let library = device.makeDefaultLibrary() else { return false }
            guard
                let vertexFunction = library.makeFunction(name: "vertex_main"),
                let fragmentFunction = library.makeFunction(name: "fragment_main")
            else {
                return false
            }

            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float2
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[1].format = .float2
            vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
            vertexDescriptor.attributes[1].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexDescriptor = vertexDescriptor

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                return false
            }
            return true
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard
                isReady,
                let pipelineState,
                let vertexBuffer,
                let commandQueue,
                let drawable = view.currentDrawable,
                let renderPassDescriptor = view.currentRenderPassDescriptor,
                let commandBuffer = commandQueue.makeCommandBuffer(),
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            else {
                return
            }

            let currentTime = Float(CFAbsoluteTimeGetCurrent() - startTime)
            var uniforms = Uniforms(
                time: currentTime,
                resolution: SIMD2<Float>(
                    Float(view.drawableSize.width),
                    Float(view.drawableSize.height)
                ),
                glowPosition: SIMD2<Float>(0.5, 0.5),
                isLight: isLight ? 1.0 : 0.0
            )

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
