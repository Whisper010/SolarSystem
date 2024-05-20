//
//  renderScene.swift
//  SolarSystem
//
//  Created by Linar Zinatullin on 06/05/24.
//

import Foundation

class RenderScene: ObservableObject {
    
    let camera: Camera
    let sunLight: Sun
    var planets: [Planet]
    var objectsToRender: [Renderable]
    
    var screenSize: CGSize
    
    var radius: Float = 0.0
    var lastMagnification: CGFloat = 0.0
    var lastDragging: CGSize = .zero
    
    var center: simd_float3 = [0.0, 0.0, 0.0]
    var observeRadius: Float = 10000
    var zoomFactor: Float = 500
    
    struct Offset {
        var position: simd_float3 = [0.0,0.0,0.0]
    }
    
    var offset: Offset = Offset()
    
    @Published var speedAdjustment: Float = 1.0
    
    var spinCenter: simd_float3 = [0.0,0.0,0.0]
    
    @Published var focusPlanet: Planet? {
        didSet {
            if let planet = focusPlanet{
                observeRadius = planet.scale * 100
                zoomFactor = planet.scale * 15
                radius = observeRadius
                adjustPlanetsRelativeToFocusPlanet(planet)
                updateCameraPositionFromEulers()
            }
        }
    }
    
    init(){
        screenSize = CGSize(width: 0.0, height: 0.0)
        
        planets = []
        objectsToRender = []
        
        camera = Camera (
            name: "camera",
            position: [-10000.0, 6.0, 4.0],
            eulers: [0.0,110.0, -45.0]
        )
        
        let newSun = Sun(name: "SunLight",position: [0, 0,0], eulers: [0.0,135.0, 45.0], color: [1.0, 0.95, 0.8,1.0])
        newSun.declareDirectional(eulers: [0.0,135.0, 45.0])
        newSun.update()
        sunLight = newSun
        
        
        
       
        lastMagnification = 1.0
        
        planets.append(contentsOf: createPlanets())
        
        if let sun = planets.first(where: {$0.name == "Sun"}) {
            setFocus(to: sun)
        }
        
        objectsToRender = planets
        for object in planets {
            object.update()
        }
        updateCameraPositionFromEulers()
       
        
    }
    
    func update() {
        movePlanets()
    }
    
}



// TODO: Updates
extension RenderScene{
    func updateObjectsToRender() {
        objectsToRender = planets.compactMap{$0 as? Renderable}
    }
    
    func setFocus(to planet: Planet) {
        center = planet.position
        updateCameraPositionFromEulers()
    }
    
    func adjustPlanetsRelativeToFocusPlanet(_ focusPlanet: Planet) {
        offset.position = focusPlanet.position
        for planet in planets {
            planet.position -= offset.position
        }
        spinCenter -= offset.position
    }
    
    func movePlanets() {
        
        for pl in planets {
            let planet = pl
            if planet != focusPlanet {
                    // Increment the orbital angle based on the orbital speed
                    planet.orbitalAngle += planet.orbitalSpeed * (.pi / 180) * speedAdjustment
                    if planet.orbitalAngle > 2 * .pi {
                        planet.orbitalAngle -= 2 * .pi
                    }
                    
                    // Calculate the radius
                    let radius = length(planet.position - spinCenter)
                    
                    // Calculate the new position based on the accumulated orbital angle
                    let newX = spinCenter.x + radius * cos(planet.orbitalAngle)
                    let newY = spinCenter.y + radius * sin(planet.orbitalAngle)
                    planet.position = SIMD3<Float>(newX, newY, planet.position.z)
                    
            }
            
            
                // Increment the rotational angle based on the rotational speed
                planet.rotationalAngle += planet.rotationalSpeed * speedAdjustment
                if planet.rotationalAngle > 360 {
                    planet.rotationalAngle -= 360
                }
                
                // Update the planet's rotation around its own axis
                planet.eulers.z = planet.rotationalAngle
            
            
            planet.update()
        }
    }
}


// TODO: Gestures
extension RenderScene {
    
    func updateCameraPositionFromEulers() {
        radius = max(observeRadius / 5, min(radius, observeRadius))
        camera.position = sphericalToCartesian(radius: radius, eulers: camera.eulers)
        camera.update()
    }
    
    func calculateRadius() -> Float {
        sqrt(pow(center.x - camera.position.x, 2) + pow(center.y - camera.position.y, 2) + pow(center.z - camera.position.z, 2))
    }
    
    func sphericalToCartesian(radius: Float, eulers: vector_float3) -> vector_float3 {
        [center.x - radius * cos(eulers.z * .pi / 180.0) * sin(eulers.y * .pi / 180.0),
         center.z - radius * sin(eulers.z * .pi / 180.0) * sin(eulers.y * .pi / 180.0),
         center.y - radius * cos(eulers.y * .pi / 180.0)]
    }
    
    func zoomCamera(offset: CGFloat) {
        
        radius = calculateRadius()
        
        let zoomInFactor: Float = zoomFactor
        let zoomOutFactor: Float = zoomFactor
        
        var delta = Float(lastMagnification - offset)
        
        if delta < 0 {
            delta *= zoomInFactor
        } else {
            delta *= zoomOutFactor
        }
        
        radius += delta
        
        // Clamp the radius to prevent it from going out of bounds
        radius = max(observeRadius / 5, min(radius, observeRadius))
        
        camera.position = sphericalToCartesian(radius: radius, eulers: camera.eulers)
        camera.update()
        
        // Update the last magnification scale
        lastMagnification = offset
        
        
    }
    
    func spinCamera(offset: CGSize) {
        
        let sensitivityHorizontal: Float = 0.4
        let sensitivityVertical: Float = 0.4
        
        let delta = CGSize(width: offset.width - lastDragging.width, height: offset.height - lastDragging.height )
        
        let dTheta: Float = Float(delta.width) * sensitivityHorizontal // Horizontal drag affects azimuth
        let dPhi: Float = Float(delta.height) * sensitivityVertical // Vertical drag affects polar angle
        
        camera.eulers.z +=  dTheta // azimuth
        camera.eulers.y +=  dPhi // elevation
        
        // Normalize azimuth to keep it within 0-360 degrees
        camera.eulers.z = fmod(camera.eulers.z, 360)
        
        if camera.eulers.z < 0 {
            camera.eulers.z += 360
        }
        
        // Clamp the elevation to prevent the camera from flipping over the poles
        camera.eulers.y = max(1, min(camera.eulers.y, 179))
        
        lastDragging = offset
        
        updateCameraPositionFromEulers()
        
        //        for object in planets {
        //            object.update()
        //        }
        
    }
}


// TODO: Create Instances
extension RenderScene {
    
    func createPlanets() -> [Planet] {
        var planets: [Planet] = []
        
        let scale: Float = 1.0
        let distanceScale: Float = 1496 * 2
        let orbitalSpeed: Float = 0.01
        let rotationalSpeed: Float = 1.0
        
        // Sun
        let sun: Planet = Planet(name: "Sun", position: [0.0, 0.0, 0.0], eulers: [180.0, 0.0, 0.0])
        sun.addRenderComponents(mesh: "sphere", material: "sun")
        sun.orbitalSpeed = 0.0
        sun.rotationalSpeed = rotationalSpeed * 0.254
        sun.scale = scale * 109.07
        planets.append(sun)
        
        // Mercury
        let mercury: Planet = Planet(name: "Mercury", position: [sin(90) * distanceScale * 0.387, cos(90) * distanceScale * 0.387 , 0.0], eulers: [180.0, 0.0, 0.0])
        mercury.addRenderComponents(mesh: "sphere", material: "mercury")
        mercury.orbitalSpeed = orbitalSpeed * 0.241
        mercury.rotationalSpeed = rotationalSpeed * 58.8 
        mercury.scale = scale * 0.383
        planets.append(mercury)
        
        // Venus
        let venus: Planet = Planet(name: "Venus", position: [sin(70) * distanceScale * 0.723, cos(70) * distanceScale * 0.723 , 0.0], eulers: [180.0, 0.0, 0.0])
        venus.addRenderComponents(mesh: "sphere", material: "venus")
        venus.orbitalSpeed = orbitalSpeed * 0.615
        venus.rotationalSpeed = rotationalSpeed * -244
        venus.scale = scale * 0.949
        planets.append(venus)
        
        // Earth
        let earth: Planet = Planet(name: "Earth", position: [sin(120) * distanceScale * 1.0, cos(120) * distanceScale * 1.0 , 0.0], eulers: [180.0, 0.0, 0.0])
        earth.addRenderComponents(mesh: "sphere", material: "earth")
        earth.orbitalSpeed = orbitalSpeed
        earth.rotationalSpeed = rotationalSpeed
        earth.scale = scale
        planets.append(earth)
        
        // Mars
        let mars: Planet = Planet(name: "Mars", position: [sin(150) * distanceScale * 1.52, cos(150) * distanceScale * 1.52, 0.0], eulers: [180.0, 0.0, 0.0])
        mars.addRenderComponents(mesh: "sphere", material: "mars")
        mars.orbitalSpeed = orbitalSpeed * 1.88
        mars.rotationalSpeed = rotationalSpeed * 1.03
        mars.scale = scale * 0.532
        planets.append(mars)
        
        // Jupiter
        let jupiter: Planet = Planet(name: "Jupiter", position: [sin(180) * distanceScale * 5.20, cos(180) * distanceScale * 5.20, 0.0], eulers: [180.0, 0.0, 0.0])
        jupiter.addRenderComponents(mesh: "sphere", material: "jupiter")
        jupiter.orbitalSpeed = orbitalSpeed * 11.9
        jupiter.rotationalSpeed = rotationalSpeed * 0.415
        jupiter.scale = scale * 11.21
        planets.append(jupiter)
        
        // Saturn
        let saturn: Planet = Planet(name: "Saturn", position: [sin(210) * distanceScale * 9.57, cos(210) * distanceScale * 9.57, 0.0], eulers: [180.0, 0.0, 0.0])
        saturn.addRenderComponents(mesh: "sphere", material: "saturn")
        saturn.orbitalSpeed = orbitalSpeed * 29.4
        saturn.rotationalSpeed = rotationalSpeed * 0.445
        saturn.scale = scale * 9.45
        planets.append(saturn)
        
        // Uranus
        let uranus: Planet = Planet(name: "Uranus", position: [sin(240) * distanceScale * 19.17, cos(240) * distanceScale * 19.17, 0.0], eulers: [180.0, 0.0, 0.0])
        uranus.addRenderComponents(mesh: "sphere", material: "uranus")
        uranus.orbitalSpeed = orbitalSpeed * 83.7
        uranus.rotationalSpeed = rotationalSpeed * -0.720
        uranus.scale = scale * 4.01
        planets.append(uranus)
        
        // Neptune
        let neptune: Planet = Planet(name: "Neptune", position: [sin(270) * distanceScale * 30.18, cos(270) * distanceScale * 30.18, 0.0], eulers: [180.0, 0.0, 0.0])
        neptune.addRenderComponents(mesh: "sphere", material: "neptune")
        neptune.orbitalSpeed = orbitalSpeed * 163.7
        neptune.rotationalSpeed = rotationalSpeed * 0.673
        neptune.scale = scale * 3.88
        planets.append(neptune)
        
        // Pluto
        let pluto: Planet = Planet(name: "Pluto", position: [sin(300) * distanceScale * 39.48, cos(300) * distanceScale * 39.48, 0.0], eulers: [180.0, 0.0, 0.0])
        pluto.addRenderComponents(mesh: "sphere", material: "pluto")
        pluto.orbitalSpeed = orbitalSpeed * 247.9
        pluto.rotationalSpeed = rotationalSpeed * 6.41
        pluto.scale = scale * 0.187
        planets.append(pluto)
        
        return planets
        
        
    }
}
