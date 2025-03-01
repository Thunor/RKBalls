//
//  Body.swift
//  RKBalls
//
//  Created by Eric Freitas on 3/1/25.
//
import SwiftUI
import RealityKit
import Combine

struct PCameraView: View {
    @State var camera: PerspectiveCamera =  PerspectiveCamera()
    @State var entity: Entity?
    
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            camera.camera.fieldOfViewInDegrees = 60
            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)
            content.add(cameraAnchor)
            if let myEntity = try? await Entity.init(named: "my_entity") {
                entity = myEntity
                content.add(entity!)
                //                camera.look(at: entity?.position, from: <#T##SIMD3<Float>#>, relativeTo: <#T##Entity?#>)
                camera.look(at: myEntity.position, from: SIMD3<Float>(0,0,1), relativeTo: nil)
            }
        }
        .realityViewCameraControls(.pan) //Set up controls like Scenekit has
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded({ value in
            debugPrint("____ tapped")
            //Do something
        }))
    }
}

