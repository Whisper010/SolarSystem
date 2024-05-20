//
//  SimpleComponent.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 08/05/24.
//

import Foundation

class Planet: SimpleComponent, Identifiable, Equatable {
    static func == (lhs: Planet, rhs: Planet) -> Bool {
        lhs.name == rhs.name
    }
    

    var id = UUID()
    
    var name: String
    
    var model: matrix_float4x4
    var position: simd_float3
    var eulers: simd_float3
    
    var scale: Float
    
    var color: vector_float4
    var material: String?
    var mesh: String?

    var orbitalSpeed: Float = 0.0
    var rotationalSpeed: Float = 0.0
    
    var orbitalAngle: Float = 0.0
    var rotationalAngle: Float = 0.0
    
    init (name: String, position: simd_float3, eulers: simd_float3) {
        
        self.name = name
        
        self.position = position
        self.eulers = eulers
        self.model = Matrix44.create_identity()
        self.scale = 1.0
        
        self.color = [1.0,1.0,1.0,1.0]
    }
    
    func update() {
        model = Matrix44.create_from_rotation(eulers: eulers)
        model = Matrix44.create_from_translation(translation: position) * model
        model *= Matrix44.create_scale(sx: scale, sy: scale, sz: scale)
    }
    
    func addRenderComponents(mesh: String, color: vector_float4 = [1.0,1.0,1.0,1.0], material: String? = nil) {
        self.mesh = mesh
        self.material = material
        self.color = color
    }
    
    
}







