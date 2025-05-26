//
//  ContentView.swift
//  RKBalls
//
//  Created by Eric Freitas on 2/19/25.
//

import SwiftUI
import RealityKit
import Combine
import GLKit


struct ModelExample: View {
    @State var camera: PerspectiveCamera =  PerspectiveCamera()
    @State private var rContent: RealityViewCameraContent?
    @State var zoomFactor: Float = 1.0
    @State var planetTexture: TextureResource?
    @State private var anchorEntity: AnchorEntity?
    @State private var centerTarget: Entity?
    @State private var infoTarget: Entity?
    @State private var rotAngleY: Float = 0.0
    @State private var rotAngleX: Float = 0.0
    @State private var dragStartAngleY: Float = 0.0
    @State private var dragStartAngleX: Float = 0.0
    @State private var dragActive = false
    
    // State to track pivot point
    @State private var pivotPoint: SIMD3<Float> = .zero
    
    var imageName: String = "Azul_4096"
    
    var flag: Bool = false
    
    
    init() {
        // Make sure to register the component!
        AllowGestures.registerComponent()
    }
    
    var body: some View {
        ZStack {
            
            RealityView { content in
                
                // Setup the anchor
                let anchorEntity = setupAnchor()
                content.add(anchorEntity)

                // Setup the camera
                camera = setupCamera()
                anchorEntity.addChild(camera)
                
                // Setup the content for use in other local functions
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
                redSunME.components[AllowGestures.self] = .init()
                anchorEntity.addChild(redSunME)
                
                // create a single object near the sun
                
                planetTexture = try? await TextureResource(named: imageName)
                let rockPlanet = MeshResource.generateSphere(radius: 0.1)
                var rockPlanetMat = SimpleMaterial(color: .white, roughness: 0.8, isMetallic: false)
                if let planetTexture {
                    rockPlanetMat.color = PhysicallyBasedMaterial
                        .BaseColor(texture: .init(planetTexture))
                }
                let rockPlanetME = ModelEntity(mesh: rockPlanet, materials: [rockPlanetMat])
                rockPlanetME.position = [1.0, 0, 0]
                rockPlanetME.name = "white_Rock"
                rockPlanetME.generateCollisionShapes(recursive: false)
                rockPlanetME.components[AllowGestures.self] = .init()
                anchorEntity.addChild(rockPlanetME)
                
                // load an object and give it an orbit to follow
                if let ringsted = try? await ModelEntity(named: "Ringsted") {
                    ringsted.position = [1.5, 0, 0]
                    ringsted.scale = [0.01, 0.01, 0.01]
                    ringsted.generateCollisionShapes(recursive: false)
                    ringsted.name = "Ringsted"
                    let pivot = Entity()
                    pivot.position = rockPlanetME.position
                    pivot.addChild(ringsted)
                    
                    let orbit = OrbitAnimation(
                        duration: 50.0,
                        startTransform: Transform(translation: pivot.position),
                        spinClockwise: false,
                        bindTarget: .transform,
                        repeatMode: .repeat)
                    
                    if let animation = try? AnimationResource.generate(with: orbit) {
                        ringsted.playAnimation(animation)
                    }
                    
                    ringsted.transform.rotation = simd_quatf(
                        angle: .pi * 2.0,
                        axis: SIMD3<Float>(x: 0, y: 1, z: 0)
                    )
                    ringsted.components[AllowGestures.self] = .init()
                }
                
                // Create a bunch of sphere objects
                for n in 0..<1000 {
                    // can add a texture to a sphere, like so
                    // var rock = rock(texture: planetTexture)
                    let rock = rock(texture: nil)
                    rock.name = "rock_\(n)"
                    rock.position = SIMD3<Float>.random(in: -20...20, using: &OnyxRandomGen.randGen)
                    rock.generateCollisionShapes(recursive: false)
                    rock.components[AllowGestures.self] = .init()
                    anchorEntity.addChild(rock)
                }
                
                // set which object to look at
                content.cameraTarget = redSunME
                
                self.anchorEntity = anchorEntity
            } update: { content in
                // Update existing content when view updates
                if let starField = content.entities.first {
                    // Apply zoom transform around pivot point
                    updateStarFieldTransform(starField)
                }
                updateCameraTransform(camera)
            }
            .background(Color.black)
            .gesture(TapGesture(count: 2).targetedToEntity(where: .has(AllowGestures.self)).onEnded { gesture in
                if let hitEntity = gesture.entity as? ModelEntity {
                    pivotPoint = hitEntity.position(relativeTo: nil)
//                    selectedStarId = hitEntity.id
                }
            })
            .simultaneousGesture(TapGesture(count: 1).targetedToEntity(where: .has(AllowGestures.self)).onEnded({ gesture in
                print("got tap for", gesture.entity.name)
                infoTarget = gesture.entity
            }))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !dragActive {
                            dragStartAngleY = rotAngleY
                            dragStartAngleX = rotAngleX
                            dragActive = true
                        }
                        // Horizontal drag: Y axis rotation (azimuth)
                        rotAngleY = dragStartAngleY + Float(value.translation.width) * -0.2
                        rotAngleY.formTruncatingRemainder(dividingBy: 360)
                        // Vertical drag: X axis rotation (elevation)
                        rotAngleX = dragStartAngleX + Float(value.translation.height) * 0.2
                        rotAngleX = min(max(rotAngleX, -89), 89)
                    }
                    .onEnded { _ in
                        dragActive = false
                    }
            )
//            .onKeyPress(characters: .letters) { key in
//                debugPrint("key: \(key)")
//                switch key.key {
//                    case "a":
//                        debugPrint("pressed a")
//                        rotAngleY += 10.0
//                        rotAngleY.formTruncatingRemainder(dividingBy: 360) // Keep within 0-360 degrees
//                        
//                    case "d":
//                        debugPrint("pressed d")
//                        rotAngleY -= 10.0
//                        rotAngleY.formTruncatingRemainder(dividingBy: 360) // Keep within 0-360 degrees
//                    default:
//                        debugPrint("pressed \(key.key)")
//                }
//                return .handled
//            }
            
            HStack {
                Spacer()
                HStack{
                    VStack {
                        DataView(entity: $infoTarget)
                        Text("Scale: \(zoomFactor)")
                        Text("Rot Angle: \(rotAngleY), \(rotAngleX)")
                        Spacer()
                    }
                }
                .frame(width: 200)
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(Color.controlBackground))
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            }
        }
    }
  
    private func updateStarFieldTransform(_ entity: Entity) {
        entity.transform = .identity
        if pivotPoint != .zero {
            // Move pivot to origin, scale, then move back
            let toOrigin = Transform(translation: -pivotPoint)
            let scale = Transform(scale: SIMD3<Float>(repeating: zoomFactor))
            let fromOrigin = Transform(translation: pivotPoint)
            // Correct order: T(pivot) * S * T(-pivot)
            entity.transform.matrix = fromOrigin.matrix * scale.matrix * toOrigin.matrix
        } else {
            entity.transform.matrix = Transform(scale: SIMD3<Float>(repeating: zoomFactor)).matrix
        }
    }
    
    private func updateCameraTransform(_ camera: Entity) {
        let radius: Float = 20.0 * zoomFactor
        let azimuth = rotAngleY * (.pi / 180)
        let elevation = rotAngleX * (.pi / 180)
        let x = radius * cos(elevation) * sin(azimuth)
        let y = radius * sin(elevation)
        let z = radius * cos(elevation) * cos(azimuth)
        camera.position = [x, y, z] + pivotPoint
        camera.look(at: pivotPoint, from: camera.position, relativeTo: nil)
    }
    
    func setupAnchor() -> AnchorEntity {
        let anchorEntity = AnchorEntity(world: [0, 0, 0])
        anchorEntity.components.set(InputTargetComponent())
        anchorEntity.name = "anchor"
        return anchorEntity
    }
    
    func setupCamera() -> PerspectiveCamera {
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 60
        camera.name = "pcamera"
        camera.position = [0, 0, 20]
        camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
        return camera
    }
    
    // MARK: used to create a number of spheres, one at a time
    func rock(texture: TextureResource?) -> ModelEntity {
        let brownRock = MeshResource.generateSphere(radius: Float.random(in: 0.05...0.1, using: &OnyxRandomGen.randGen))
        var brownRockMaterial = SimpleMaterial()
        // Make different colored stars for visual variety
        let colors: [Color] = [.white, .yellow, .cyan, .orange, .red]
        let randomColor = colors[Int.random(in: 0...4)]
        brownRockMaterial.color = .init(tint: NSColor(randomColor), texture: nil)
        brownRockMaterial.__emissive = .color(NSColor(randomColor).cgColor)
        let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
        return brownRockME
    }
}


#Preview {
    ModelExample()
}
