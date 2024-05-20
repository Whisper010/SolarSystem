//
//  appView.swift
//  Transformations
//
//  Created by Linar Zinatullin on 06/05/24.
//

import SwiftUI

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
            
    }
    
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}


struct appView: View {
    
    @EnvironmentObject var renderScene: RenderScene
    
    @State var orientation = UIDeviceOrientation.unknown
    
    
    var body: some View {
        VStack{
            ZStack {
                GeometryReader { geo in
                    ContentView()
                        .gesture(
                            DragGesture()
                                .onChanged{ gesture in
                                    renderScene.spinCamera(offset: gesture.translation)
                                }
                                .onEnded{_ in
                                    renderScene.lastDragging = .zero
                                }
                        )
                        .gesture(MagnificationGesture(minimumScaleDelta: 0.2)
                            .onChanged{ gesture in
                                renderScene.zoomCamera(offset: gesture )
                            }
                            .onEnded{_ in
                                renderScene.lastMagnification = 1.0
                                
                                renderScene.radius = renderScene.calculateRadius()
                                
                            }
                        )
                        .onRotate{ newOriantation in
                            orientation = newOriantation
                        }
                        .onChange(of: orientation) {
                            renderScene.screenSize = geo.size
                        }
                }
                VStack {
                    HStack(){
                        Button(action: {
                            renderScene.speedAdjustment = 0.0
                        }) {
                            Image(systemName: "pause")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            renderScene.speedAdjustment = 1.0
                        }) {
                            Image(systemName: "play")
                        }
                        .buttonStyle(.bordered)
    
                    }.padding()
                        .accentColor(.white)
                    
                    
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    VStack() {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(renderScene.planets) { planet in
                                Button(action: {
                                    renderScene.focusPlanet = planet
                                }) {
                                    Text(planet.name)
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                              
                            }
                        }
                        .padding()
                        .background(Material.ultraThin.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                   
                    
                    
                }.padding()
            }
        }
    }
}

#Preview {
    appView()
        .environmentObject(RenderScene())
}
