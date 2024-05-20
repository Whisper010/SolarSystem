//
//  material.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 12/05/24.
//

import MetalKit

class Texture{
    
    let texture: MTLTexture
    let sampler : MTLSamplerState
    
    init(device: MTLDevice, allocator: MTKTextureLoader, filename: String) {
        
        let name = filename.replacingOccurrences(of: ".jpg", with: "").replacingOccurrences(of: ".png", with: "")
        
       
        let extensions = ["jpg", "png"]
        var foundMaterialURL: URL? = nil
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                foundMaterialURL = url
                break
            }
        }
        
        guard let materialURL = foundMaterialURL else {
            fatalError("Couldn't load texture")
        }
        
        let options: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .generateMipmaps: true
        ]
        
        //load texture
        do {
            texture = try allocator.newTexture(URL: materialURL
                                               ,options: options)
        } catch {
            fatalError("couldn't load texture")
        }
        
        // Dectibe options
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.maxAnisotropy = 8
        
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)!
    }
}
