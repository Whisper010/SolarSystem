//
//  SolarSystemApp.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 05/05/24.
//

import SwiftUI

@main
struct SolarSystemApp: App {
    
    @StateObject private var renderScene = RenderScene()
    
    var body: some Scene {
        WindowGroup {
            appView()
                .environmentObject(renderScene)
        }
    }
}
