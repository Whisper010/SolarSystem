//
//  ContentView.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 05/05/24.
//

import SwiftUI
import MetalKit

struct ContentView: UIViewRepresentable {
    
    @EnvironmentObject var renderScene: RenderScene
    
    func makeCoordinator() -> Renderer {
        Renderer(self, scene: renderScene)
    }
    
    func makeUIView(context: UIViewRepresentableContext<ContentView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.isPaused = false
        
        // Initialize depthStencilFormat
        mtkView.depthStencilPixelFormat = .depth32Float
        
        renderScene.screenSize = UIScreen.main.bounds.size
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<ContentView>) {
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View{
        ContentView()
    }
}
