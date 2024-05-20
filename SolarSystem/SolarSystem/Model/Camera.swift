//
//  camera.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 06/05/24.
//

import Foundation

class Camera : CameraView{

    var name: String
    
    var position: simd_float3
    var eulers: simd_float3
    
    var forwards: simd_float3
    var right: vector_float3
    var up: vector_float3
    var view: matrix_float4x4
    
    init(name: String ,position: simd_float3, eulers: simd_float3) {
        
        self.name = name
        
        self.position = position
        self.eulers = eulers
        
        self.forwards = [0.0,0.0,0.0]
        self.right = [0.0,0.0,0.0]
        self.up = [0.0,0.0,0.0]
        self.view = Matrix44.create_identity()
        
        
    }
    
    func update() {
        
        forwards = [
            cos(eulers[2] * .pi / 180.0) * sin(eulers[1] * .pi / 180.0),
            sin(eulers[2] * .pi / 180.0) * sin(eulers[1] * .pi / 180.0),
            cos(eulers[1] * .pi / 180.0)
        ]
        
        let globalUP: vector_float3 = [0.0, 0.0, 1.0]
        
        right = simd.normalize(simd.cross(globalUP, forwards))
        
        up = simd.normalize(simd.cross(forwards, right))
        
        view = Matrix44.create_lookat(eye: position, target: position + forwards, up: up)
        
    }
}
