//
//  Sun.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 19/05/24.
//

import Foundation


class Sun: Light {
 
    var name: String
    
    var position: simd_float3
    var eulers: simd_float3
    
    var color: vector_float4
    var type: LightType
    
    var forwards: simd_float3
    var right: vector_float3
    var up: vector_float3
    
    var t: Float?
    var rotationCenter: vector_float3?
    var pathRadius: Float?
    var pathPhi: Float?
    var angularVelocity: Float?
    
    
    init(name: String, position: simd_float3, eulers: simd_float3 = [0,0,0], color: vector_float4, type: LightType = UNDEFINED) {
        
        self.name = name
        
        self.position = position
        self.eulers = eulers
        
        self.color = color
        self.type = type
        
        self.forwards = [0.0,0.0,0.0]
        self.right = [0.0,0.0,0.0]
        self.up = [0.0,0.0,0.0]
    }
    
    func update() {
        switch type {
        case DIRECTIONAL:
            forwards = [
                cos(eulers[2] * .pi / 180.0) * sin(eulers[1] * .pi / 180.0),
                sin(eulers[2] * .pi / 180.0) * sin(eulers[1] * .pi / 180.0),
                cos(eulers[1] * .pi / 180.0)
            ]
//        case SPOTLIGHT:
//            
//        case POINTLIGHT:
            
        default:
            break
        }
            
            
           
    }
    
    func declareDirectional(eulers: vector_float3){
        self.type = DIRECTIONAL
        self.eulers = eulers
    }
    
    func declareSpotlight(position: vector_float3, eulers: vector_float3) {
        self.type = SPOTLIGHT
        self.position = position
        self.eulers = eulers
        self.t = 0.0
    }
    
    func declarePointLight(
        rotationCenter: vector_float3, pathRadius: Float,
        pathPhi:Float, angularVelocity: Float
    ) {
        self.type = POINTLIGHT
        self.rotationCenter = rotationCenter
        self.pathRadius = pathRadius
        self.pathPhi = pathPhi
        self.angularVelocity = angularVelocity
        self.t = 0.0
        self.position = rotationCenter
    }
}
