//
//  objMesh.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 09/05/24.
//

import MetalKit

class Mesh {
    
    let modelIOMesh: MDLMesh
    let metalMesh: MTKMesh
    
    init(device: MTLDevice, allocator: MTKMeshBufferAllocator, filename: String) {
        
        
        guard let meshURL = Bundle.main.url(forResource: filename, withExtension: "obj") else {
            fatalError()
        }
        
        
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        var offset: Int = 0
        
        // Declare position [[attribure(0)]]
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = offset
        vertexDescriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        // Declare texcoord [[attribure(1)]]
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = offset
        vertexDescriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<SIMD2<Float>>.stride
        
        // Declare texcoord [[attribure(2)]]
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset = offset
        vertexDescriptor.attributes[2].bufferIndex = 0
        offset += MemoryLayout<SIMD3<Float>>.stride
        
//        // Declare color [[attribure(3)]]
//        vertexDescriptor.attributes[3].format = .float4
//        vertexDescriptor.attributes[3].offset = offset
//        vertexDescriptor.attributes[3].bufferIndex = 0
//        offset += MemoryLayout<SIMD4<Float>>.stride
        
        vertexDescriptor.layouts[0].stride = offset
        
        
        let meshDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        (meshDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (meshDescriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (meshDescriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
//        (meshDescriptor.attributes[3] as! MDLVertexAttribute).name = MDLVertexAttributeColor
        
        let asset = MDLAsset(
            url: meshURL,
            vertexDescriptor: meshDescriptor,
            bufferAllocator: allocator
        )
        
        modelIOMesh = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
        
//        // Check if the color attribute is missing and add default color data if necessary
//        if modelIOMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeColor) == nil {
//            
//            let mesh = modelIOMesh
//            
//            let vertexCount = mesh.vertexCount
//            var colors = [SIMD4<Float>](repeating: SIMD4<Float>(1.0, 1.0, 1.0, 1.0), count: vertexCount)
//            
//            let colorData = NSData(bytes: &colors, length: MemoryLayout<SIMD4<Float>>.stride * vertexCount)
//            let colorBuffer = MDLMeshBufferData(type: .vertex, data: colorData as Data)
//            
//            let bufferIndex = mesh.vertexBuffers.count
//            let colorAttribute = MDLVertexAttribute(name: MDLVertexAttributeColor, format: .float4, offset: 0, bufferIndex: mesh.vertexBuffers.count)
//            let bufferLayout = MDLVertexBufferLayout(stride: MemoryLayout<SIMD4<Float>>.stride)
//            
//            // Add the color attribute and buffer to the mesh
//            mesh.vertexDescriptor.attributes[2] = colorAttribute
//            mesh.vertexDescriptor.layouts[bufferIndex] = bufferLayout
//            mesh.addAttribute(withName: MDLVertexAttributeColor, format: .float4)
//            mesh.vertexBuffers.append(colorBuffer)
//        }
        
        
        // load mesh
        do {
            metalMesh = try MTKMesh(mesh: modelIOMesh, device: device)
        } catch {
            fatalError("couldn't load mesh")
        }
    }
    
}

