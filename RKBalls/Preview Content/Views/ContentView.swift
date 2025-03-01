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
    
    @State private var skydome: Entity?
    @State private var indoorIbl: ImageBasedLightComponent?
    @State private var iblEntity: Entity?
    
    @State var camera: PerspectiveCamera =  PerspectiveCamera()
    
    @State private var litCube: Entity?
    @State private var redSunModelEntity: ModelEntity?
    
    @State var ticket: AnyCancellable? = nil
    
    var body: some View {
        RealityView { content in
            
            content.camera = .virtual
            debugPrint("____ entity count: \(content.entities.count)")
            let anchorEntity = AnchorEntity(world: [0, 0, 0])
            
            let redSun = MeshResource.generateSphere(radius: 0.5)
            //            let material = SimpleMaterial(color: .red, roughness: 1.0, isMetallic: false)
            var pMat = PhysicallyBasedMaterial()
            pMat.emissiveIntensity = 0.05
            pMat.emissiveColor = .init(color: .red)
            pMat.baseColor = .init(tint: .red)
            //            pMat.
            //            var unlitMat = UnlitMaterial(color: .red)
            let redSunME = ModelEntity(mesh: redSun, materials: [pMat])
            redSunModelEntity = redSunME
            anchorEntity.addChild(redSunME)
            
            //            let lightEntity = try! getLightEntity()
            //            redSunME.addChild(lightEntity)
            
            let brownRock = MeshResource.generateSphere(radius: 0.1)
            //            let brownRockMaterial = UnlitMaterial(color: .white)
            let brownRockMaterial = SimpleMaterial(color: .white, roughness: 0.8, isMetallic: false)
            let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
            brownRockME.position = [1.0, 0, 0]
            anchorEntity.addChild(brownRockME)
            
            for _ in 0..<100 {
                var rock = rock()
                rock.position = SIMD3<Float>.random(in: -20...20)
                anchorEntity.addChild(rock)
            }
            
            content.add(anchorEntity)
            
            
            camera.camera.fieldOfViewInDegrees = 60
            let cameraAnchor = anchorEntity //AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)
            camera.position = [0, 0, 10]
            content.add(cameraAnchor)
            camera.look(at: redSunME.position, from: SIMD3<Float>(0,0,1), relativeTo: nil)
            
            trackScrollWheel()
        } update: { content in
            if let redSunModelEntity = redSunModelEntity {
                camera.look(at: redSunModelEntity.position, from: camera.position, relativeTo: nil)
            }
        }
        .realityViewCameraControls(CameraControls.orbit)
        .background(Color.black)
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({ value in
            debugPrint("____ tapped")
        }))
        .onKeyPress { KeyPress in
            debugPrint("____ key pressed: \(KeyPress.key)")
            // FIXME: this should change differently
            if KeyPress.key == "w" {
                camera.position.z += 0.1
            } else if KeyPress.key == "s" {
                camera.position.z -= 0.1
            }
            return .handled
        }
        
    }
    
    func rock() -> ModelEntity {
        let brownRock = MeshResource.generateSphere(radius: Float.random(in: 0.05...0.6))
        let brownRockMaterial = SimpleMaterial(color: .brown, roughness: 0.8, isMetallic: false)
        let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
        
        return brownRockME
    }
    
    func getLightEntity() throws -> Entity {
        let entity = Entity()
        let pointLightComponent = PointLightComponent( cgColor: .init(red: 1, green: 1, blue: 1, alpha: 1), intensity: 500000, attenuationRadius: 2000.0 )
        entity.components.set(pointLightComponent)
        entity.position = .init(x: 0.6, y: 0, z: 0.6)
        return entity
    }
    
    // Handle zoom through scrollwheel
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
                        debugPrint("____ delta: \(delta)")
                        let ddelta = delta / 10
                        camera.position += [0, 0, Float(ddelta)]
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
