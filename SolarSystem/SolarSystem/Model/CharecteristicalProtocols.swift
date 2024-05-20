//
//  Entity.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 12/05/24.
//

import Foundation


protocol Entity{
    
    var name: String {get set}
    
    func update()
}

protocol Translatable {
    var position: simd_float3 { get set }
}
protocol Rotatable {
    var eulers: simd_float3 { get set }
   
}

protocol Movable {
    var orbitalAngle: Float {get set}
    var rotationalAngle: Float {get set}
    
    var orbitalSpeed: Float {get set}
    var rotationalSpeed: Float {get set}
}

protocol Scalable {
    var scale: Float {get set}
}

protocol Directable {
    var forwards: simd_float3 { get set }
    var right: vector_float3 { get set }
    var up: vector_float3 { get set }
}

protocol Viewvable: Directable {
    var view: matrix_float4x4 { get set }
}



protocol Transformable: Translatable & Rotatable & Scalable {
   
}

protocol Colorable {
    var color: vector_float4 {get set}
}

protocol Illuminable: Colorable {
    var type: LightType {get set}
    var t: Float? {get set}
    var rotationCenter: vector_float3? {get set}
    var pathRadius: Float? {get set}
    var pathPhi: Float? {get set}
    var angularVelocity: Float? {get set}
}

protocol Renderable: Colorable {
    
    var model: matrix_float4x4 {get set}
    var material: String? {get set}
    var mesh: String? {get set}
    
    func addRenderComponents(mesh: String, color: vector_float4, material: String?)
}

protocol CameraView: Entity & Viewvable & Translatable & Rotatable {
    
}

protocol SimpleComponent: Entity & Renderable & Transformable & Movable{
    
}

protocol Light: Entity & Illuminable & Translatable & Rotatable  & Directable {
    
}



