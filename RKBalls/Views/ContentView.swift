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
    @State private var useTilt: Bool = false
    
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
                content.camera = .virtual
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
                    
//                    let oAnim = from
                    
                    let orbit = OrbitAnimation(duration: 50.0,
                                               axis: [0,0,-1],
//                                               startTransform: ringsted.transform,
                                               startTransform: Transform(translation: pivot.position),
                                               spinClockwise: false,
                                               bindTarget: .transform,
                                               repeatMode: .repeat)
                    
                    if let animation = try? AnimationResource.generate(with: orbit) {
                        ringsted.playAnimation(animation)
                    }
                    
                    ringsted.transform.rotation = simd_quatf(angle: .pi * 2.0, axis: SIMD3<Float>(x: 0, y: 1, z: 0))
                    ringsted.components[AllowGestures.self] = .init()
                    
//                    anchorEntity.addChild(ringsted)
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
//                debugPrint("camera.position: \(camera.position)")
//                content.cameraTarget = centerTarget
//                camera.position = SIMD3<Float>(scale,scale,scale)
                
                // Update existing content when view updates
                if let starField = content.entities.first {
                    // Apply zoom transform around pivot point
                    updateStarFieldTransform(starField)
                }
            }
            // Experiment with changing the camera control method:
                    .realityViewCameraControls(useTilt ? CameraControls.tilt : CameraControls.orbit)
            
//            .realityViewCameraControls(CameraControls.orbit)
            .background(Color.black)
//            .onKeyPress { KeyPress in
//                if KeyPress.key == "w" {
//                    if scale > 0.7 {
//                        scale -= 0.1
//                    }
//                } else if KeyPress.key == "s" {
//                    scale += 0.1
//                }
//                if KeyPress.key == "z" {
//                    useTilt.toggle()
//                }
//                return .handled
//            }
            .gesture(TapGesture(count: 2).targetedToEntity(where: .has(AllowGestures.self)).onEnded { gesture in

                if let hitEntity = gesture.entity as? ModelEntity {
                    pivotPoint = hitEntity.position
//                    selectedStarId = hitEntity.id
                }
//                if var anchorPos = anchorEntity?.position(relativeTo: nil) {
//                    if gesture.entity.position != anchorPos {
////                        scale = 1.0
//                        // need to zoom into a specific distance
//                        
////                        let relativeCamPos = anchorPos - camera.position
////                        camera.position = gesture.entity.position - relativeCamPos
////                        
//////                        anchorPos = -gesture.entity.position
////                        self.centerTarget = gesture.entity
////                        self.infoTarget = gesture.entity
////                        anchorEntity?.position = -anchorPos
//                        
//                        print("++ anchorPos:               \(anchorPos)")
////                        debugPrint("gesture.entity.position: \(gesture.entity.position)")
////                        debugPrint("old camera.position:     \(camera.position)")
//                        
//                        let relativeCamPos = anchorPos - camera.position
//                        anchorPos = -gesture.entity.position
////                        camera.position = gesture.entity.position - relativeCamPos
//                        self.centerTarget = gesture.entity
//                        self.infoTarget = gesture.entity
////                        anchorEntity?.position = anchorPos
//                        
//                        print("++ camera.position:     \(camera.position)")
//                        print("++ anchorEntity?.position:  \(anchorEntity?.position)")
//                    }
//                }
            })
            .simultaneousGesture(TapGesture(count: 1).targetedToEntity(where: .has(AllowGestures.self)).onEnded({ gesture in
                print("got tap for", gesture.entity.name)
                infoTarget = gesture.entity
            }) )
            .onAppear(perform:{
                // handle scroll wheel events
//                NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
//                    let ddelta: Float = Float(-event.scrollingDeltaY / 100)
//                    reScale(ddelta: ddelta)
//                    return event
//                }
            })
            
            HStack {
                Spacer()
                HStack{
                    VStack {
                        DataView(entity: $infoTarget)
                        Text("Scale: \(zoomFactor)")
                        Text("Use Tilt: \(useTilt)")
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
        // Reset transform
        entity.transform = .identity

        // Only apply if a star is selected
        if pivotPoint != .zero {
            // 1. Move pivot point to origin
            let toOrigin = Transform(translation: -pivotPoint)
            // 2. Scale around origin
            let scale = Transform(scale: SIMD3<Float>(repeating: zoomFactor))
            // Combine transforms: T(pivot) * S * T(-pivot)
            entity.transform.matrix = scale.matrix * toOrigin.matrix
        } else {
            // Just apply zoom at origin if no pivot
            entity.transform.scale = .init(repeating: zoomFactor)
        }
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
        let randomCol = randomColor()
        var brownRockMaterial = SimpleMaterial(color: randomCol, roughness: 0.8, isMetallic: false)
//        brownRockMaterial.
        if let texture {
            brownRockMaterial.color = PhysicallyBasedMaterial
                .BaseColor(texture: .init(texture))
        }
        let brownRockME = ModelEntity(mesh: brownRock, materials: [brownRockMaterial])
        return brownRockME
    }
    
    // MARK: Scale the view
//    func reScale(ddelta: Float) {
//        if let rContent = self.rContent {
//            let _ = rContent.entities.map { entity in
//                scale += ddelta
//                if scale < 0.6 { scale = 0.6 }
//            }
//        }
//    }
    
    // SIMD3<Float>(scale + 0.01,scale + 0.01,scale + 0.01)
    func calculateCameraDirection(/*cameraNode: SCNNode*/) -> SIMD3<Float> {
        let x = -camera.transform.rotation.vector.x
        let y = -camera.transform.rotation.vector.y
        let z = -camera.transform.rotation.vector.z
        let w = -camera.transform.rotation.vector.w
        
        let xy = x * y
        let xz = x * z
        let yx = y * x
        let yz = y * z
        let zx = z * x
        let zy = z * y
        let cw1 = 1 - cos(w)
        
        let cameraRotationMatrix = GLKMatrix3Make(Float(cos(w) + pow(x, 2) * cw1),
                                                  Float(xy * cw1 - z * sin(w)),
                                                  Float(xz * cw1 + y*sin(w)),
                                                  
                                                  Float(yx * cw1 + z*sin(w)),
                                                  Float(cos(w) + pow(y, 2) * cw1),
                                                  Float(yz * cw1 - x*sin(w)),
                                                  
                                                  Float(zx * cw1 - y*sin(w)),
                                                  Float(zy * cw1 + x*sin(w)),
                                                  Float(cos(w) + pow(z, 2) * cw1))
        
        let cameraDirection = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        //        simd_float3(from: cameraDirection as! Decoder)
        let camDirectionSIMD3 = simd_float3(x: cameraDirection.x, y: cameraDirection.y, z: cameraDirection.z)
        //        return SCNVector3FromGLKVector3(cameraDirection)
        return camDirectionSIMD3
    }
}

//#Preview {
//    ModelExample()
//}
