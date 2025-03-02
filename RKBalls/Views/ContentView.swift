//
//  ContentView.swift
//  RKBalls
//
//  Created by Eric Freitas on 2/19/25.
//

import SwiftUI
import RealityKit
import Combine


struct ModelExample: View {
    
    @State var camera: PerspectiveCamera =  PerspectiveCamera()
    @State private var redSunModelEntity: ModelEntity?
    @State private var rContent: RealityViewCameraContent?
    @State var ticket: AnyCancellable? = nil
    @State var scale: Float = 1.0
    
    var body: some View {
        RealityView { content in
            
            // Setup the anchor
            let anchorEntity = AnchorEntity(world: [0, 0, 0])
            anchorEntity.components.set(InputTargetComponent())
            anchorEntity.name = "anchor"
            
            // Setup the camera
            content.camera = .virtual
            content.add(anchorEntity)
            camera.camera.fieldOfViewInDegrees = 60
            camera.name = "pcamera"
            let cameraAnchor = anchorEntity
            cameraAnchor.addChild(camera)
            camera.position = [0, 0, 10]
            content.add(cameraAnchor)
            
            rContent = content
            
            // create a red sun object
            let redSun = MeshResource.generateSphere(radius: 0.5)
            var pMat = PhysicallyBasedMaterial()
            pMat.emissiveIntensity = 0.05
            pMat.emissiveColor = .init(color: .red)
            pMat.baseColor = .init(tint: .red)
            let redSunME = ModelEntity(mesh: redSun, materials: [pMat])
            redSunME.name = "redSun"
            redSunME.generateCollisionShapes(recursive: false)
            redSunModelEntity = redSunME

            anchorEntity.addChild(redSunME)
            
            // create a single object near the sun
            let brownRock = MeshResource.generateSphere(radius: 0.1)
            let brownRockMaterial = SimpleMaterial(color: .white, roughness: 0.8, isMetallic: false)
            let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
            brownRockME.position = [1.0, 0, 0]
            brownRockME.name = "white_Rock"
            brownRockME.generateCollisionShapes(recursive: false)
            anchorEntity.addChild(brownRockME)
            
            // Create a bunch of rock objects
            for n in 0..<100 {
                var rock = rock()
                rock.name = "rock_\(n)"
                rock.position = SIMD3<Float>.random(in: -20...20)
                rock.generateCollisionShapes(recursive: false)
                anchorEntity.addChild(rock)
            }
            
            // set which object to look at
            content.cameraTarget = redSunME
            
            // handle scroll wheel events
            trackScrollWheel()
        } update: { content in
            // MARK: Get the camera and move it's position
            let entIdx = content.entities.first?.children.firstIndex { entity in
                entity.name == "pcamera"
            }
            if let entIdx {
                content.entities.first?.children[entIdx].position = SIMD3<Float>(scale,scale,scale)
            }
        }
        .realityViewCameraControls(CameraControls.orbit)
        .background(Color.black)
        .onKeyPress { KeyPress in
            if KeyPress.key == "w" {
                if scale > 0.7 {
                    scale -= 0.1
                }
            } else if KeyPress.key == "s" {
                scale += 0.1
            }
            return .handled
        }
        .gesture(TapGesture(count: 2).targetedToAnyEntity().onEnded { gesture in
            print("got double tap for", gesture.entity.name)
        })
        .gesture(TapGesture(count: 1).targetedToAnyEntity().onEnded { gesture in
            print("got tap for", gesture.entity.name)
        })
        
    }
    
    // MARK: used to create a number of spheres, one at a time
    func rock() -> ModelEntity {
        let brownRock = MeshResource.generateSphere(radius: Float.random(in: 0.05...0.6))
        let brownRockMaterial = SimpleMaterial(color: .cyan, roughness: 0.8, isMetallic: false)
        let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
        
        return brownRockME
    }
    
    // MARK: Unused point light source.  Need to find out how to remove or override the default lighting.
    func getLightEntity() throws -> Entity {
        let entity = Entity()
        let pointLightComponent = PointLightComponent( cgColor: .init(red: 1, green: 1, blue: 1, alpha: 1), intensity: 500000, attenuationRadius: 2000.0 )
        entity.components.set(pointLightComponent)
        entity.position = .init(x: 0.6, y: 0, z: 0.6)
        return entity
    }
    
    // MARK: Scale the view
    func reScale(ddelta: Float) {
        if let rContent = self.rContent {
            let _ = rContent.entities.map { entity in
                scale += ddelta
                if scale < 0.6 { scale = 0.6 }
            }
        }
    }
    
    func trackScrollWheel() {
        if ticket == nil {
            var didComplete = false
            let newTicket = NSApp.publisher(for: \.currentEvent)
                .filter { event in event?.type == .scrollWheel }
                .sink(receiveCompletion: { _ in
                    didComplete = true
                    ticket = nil
                }, receiveValue: { event in
                    if let delta = event?.deltaY  {
                        let ddelta: Float = Float(-delta / 10)
                        reScale(ddelta: ddelta)
                    }
                })
            
            if !didComplete {
                ticket = newTicket
            }
        }
    }
}

#Preview {
    ModelExample()
}
