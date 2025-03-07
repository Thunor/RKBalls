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
    @State var scale: Float = 1.0
    @State var planetTexture: TextureResource?
    @State private var anchorEntity: AnchorEntity?
    
    var imageName: String = "Azul_4096"
    
    var flag: Bool = false
    
    var body: some View {
        RealityView { content in
            
            // Setup the anchor
            let anchorEntity = AnchorEntity(world: [0, 0, 0])
            anchorEntity.components.set(InputTargetComponent())
            anchorEntity.name = "anchor"
            content.add(anchorEntity)
            
            // Setup the camera
            content.camera = .virtual
            
            camera.camera.fieldOfViewInDegrees = 60
            camera.name = "pcamera"
            camera.position = [0, 0, 10]
            anchorEntity.addChild(camera)
            
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
            
            planetTexture = try? await TextureResource(named: imageName)
            let brownRock = MeshResource.generateSphere(radius: 0.1)
            var brownRockMaterial = SimpleMaterial(color: .white, roughness: 0.8, isMetallic: false)
            if let planetTexture {
                brownRockMaterial.color = PhysicallyBasedMaterial
                                      .BaseColor(texture: .init(planetTexture))
            }
            let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
            brownRockME.position = [1.0, 0, 0]
            brownRockME.name = "white_Rock"
            brownRockME.generateCollisionShapes(recursive: false)
            anchorEntity.addChild(brownRockME)
            
//            if let ringsted = try? await ModelEntity(named: "Ringsted") {
//                ringsted.position = [2.0, 0, 0]
//                ringsted.scale = [0.1, 0.1, 0.1]
//                ringsted.generateCollisionShapes(recursive: false)
//                ringsted.name = "Ringsted"
//                anchorEntity.addChild(ringsted)
//            }
            
            // Create a bunch of rock objects
            for n in 0..<100 {
//                var rock = rock(texture: planetTexture)
                let rock = rock(texture: nil)
                rock.name = "rock_\(n)"
                rock.position = SIMD3<Float>.random(in: -20...20)
                rock.generateCollisionShapes(recursive: false)
                anchorEntity.addChild(rock)
            }
            
            // set which object to look at
            content.cameraTarget = redSunME
            
            self.anchorEntity = anchorEntity
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

            let pcamEntity = anchorEntity?.children.first { $0.name == "pcamera" }
            let startPos = pcamEntity?.position ?? .zero
            pcamEntity?.move(
                to: Transform(translation: startPos - gesture.entity.position),
                relativeTo: nil,
                duration: 1.0)
            
//            anchorEntity?.move(to: Transform(translation: gesture.entity.position), relativeTo: nil, duration:  3.0)
            camera.look(at: gesture.entity.position, from: camera.position, relativeTo: nil)
        })
        .gesture(TapGesture(count: 1).targetedToAnyEntity().onEnded { gesture in
            print("got tap for", gesture.entity.name)
            camera.look(at: gesture.entity.position, from: camera.position, relativeTo: nil)
        })
        .onAppear(perform:{
            // handle scroll wheel events
            NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                let ddelta: Float = Float(-event.scrollingDeltaY / 100)
                reScale(ddelta: ddelta)
                return event
            }
        })
    }
    
    // MARK: used to create a number of spheres, one at a time
    func rock(texture: TextureResource?) -> ModelEntity {
        let brownRock = MeshResource.generateSphere(radius: Float.random(in: 0.05...0.6))
        var brownRockMaterial = SimpleMaterial(color: .cyan, roughness: 0.8, isMetallic: false)
        if let texture {
            brownRockMaterial.color = PhysicallyBasedMaterial
                                  .BaseColor(texture: .init(texture))
        }
        let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
        return brownRockME
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
}

//#Preview {
//    ModelExample()
//}
