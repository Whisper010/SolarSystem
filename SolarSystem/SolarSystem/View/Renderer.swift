//
//  Renderer.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 05/05/24.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: ContentView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
    // Allocators for mesh buffers and textures
    let allocator: MTKMeshBufferAllocator
    let materialLoader: MTKTextureLoader
    
    // Render pipeline and depth stencil states for defining how
    var pipelineState: MTLRenderPipelineState
    var depthStencilState: MTLDepthStencilState!
    
    // Scene to render
    var scene: RenderScene
    
    // Dictionaries to store loaded meshes and materials(textures)
    var meshes: [String: Mesh] = [:]
    var materials: [String?: Texture] = [:]
    
    init(_ parent: ContentView, scene: RenderScene) {
        self.parent = parent
        
        // Select which GPU to use
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        // Initialize the allocators
        self.allocator = MTKMeshBufferAllocator(device: metalDevice)
        self.materialLoader = MTKTextureLoader(device: metalDevice)
        
        // load textures and meshes
        let fileManager = FileManager.default
        let directoryPath: String = Bundle.main.bundlePath
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            
            let objFiles = files.filter{ $0.hasSuffix(".obj")}
            let texFiles = files.filter{ $0.hasSuffix(".jpg")}
            
            for filename in objFiles {
                let name = String(filename.replacingOccurrences(of: ".obj", with: ""))
                meshes[name] = Mesh(device: metalDevice, allocator: allocator, filename: name)
            }
            
            for filename in texFiles {
                let name = String(filename.replacingOccurrences(of: ".jpg", with: ""))
                materials[name] = Texture(device: metalDevice, allocator: materialLoader, filename: name)
            }
            
            
        }
         catch {
            print("Error reading directory: \(error)")
        }
        
        
        // Setup vertex and fragment drawing logic (pipelineState)
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = metalDevice.makeDefaultLibrary()
        if let library = library {
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        }
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        if let mesh = meshes["sphere"] {
            pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.metalMesh.vertexDescriptor)
        }
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        if let depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor) {
            self.depthStencilState = depthStencilState
        }
        
        do {
            try pipelineState = metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
        
        // Initialize scene
        self.scene = scene
        
        super.init()
        

    }
    
    // Called when the drawable size of the view changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    // Called to render the contents of the view
    func draw(in view: MTKView) {
        
        scene.update()
        
        guard let drawable = view.currentDrawable,
              let commandBuffer = metalCommandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        
        // Background color
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.0, 0.0, 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
        
        // Tell the render which template of drawing pipeline and depthStencil will be used
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
         
        var cameraData: CameraParameters = CameraParameters()
        cameraData.view = scene.camera.view
        cameraData.projection = calculateProjectionMatrix(screenSize: scene.screenSize)
        cameraData.position = scene.camera.position
        
        // put camera model into buffer(2)
        renderEncoder.setVertexBytes(&cameraData, length: MemoryLayout<CameraParameters>.stride, index: 2)
        
        var sun: DirectionalLight = DirectionalLight()
        sun.forwards = scene.sunLight.forwards;
        sun.color = vector_float3(scene.sunLight.color.x, scene.sunLight.color.y, scene.sunLight.color.z);
        renderEncoder.setFragmentBytes(&sun, length: MemoryLayout<DirectionalLight>.stride, index: 0)
        
       
        
        
        // Render objects in scene
        for object in scene.objectsToRender {
            if let meshKey = object.mesh,
               let mesh = meshes[meshKey]
                    {
                
                let material: Texture? = materials[object.material]
                renderObject(entity: object, mesh: mesh, with: renderEncoder, using: material)
            } else {
                print("Can't render : \(String.init(describing: object ))")
            }
        }
        
        // end of commands
        renderEncoder.endEncoding()
        
        // execute commands in GPU
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    

}

// TODO: private methods
extension Renderer{
    
    // This function calculates a perspective projection matrix
    // based on the given screen size.
    private func calculateProjectionMatrix(screenSize: CGSize) -> float4x4 {
        
        let aspect = Float(screenSize.height / screenSize.width)
        let fovx: Float = 45
        
        let fovy = 2 * atan(tan(fovx * .pi / 360) * aspect) * 180 / .pi
        
        return Matrix44.create_perspective_projective(
            fovy: fovy, aspect: aspect, near: 0.1, far: 1000000
        )
    }

    // This function handles rendering a single object in the scene.
    private func renderObject(entity: Renderable, mesh: Mesh, with renderEncoder: MTLRenderCommandEncoder, using material: Texture?) {
        
        renderEncoder.setVertexBuffer(mesh.metalMesh.vertexBuffers[0].buffer, offset: 0 , index: 0)
        
        var useTexture: Bool = false
        
        if let material = material {
            renderEncoder.setFragmentTexture(material.texture, index: 0)
            renderEncoder.setFragmentSamplerState(material.sampler, index: 0)
            useTexture = true
        } else {
            let defaultSampler = createDefaultSampler(device: renderEncoder.device)
            renderEncoder.setFragmentSamplerState(defaultSampler, index: 0)
        }
        
        var model = entity.model
        var color = entity.color
        renderEncoder.setVertexBytes(&model, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        renderEncoder.setVertexBytes(&useTexture, length: MemoryLayout<Bool>.stride, index: 3)
        renderEncoder.setVertexBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 4)
       
        
        for submesh in mesh.metalMesh.submeshes {
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
      
    }
    
    // Helper function to create a default sampler
    private func createDefaultSampler(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
}

