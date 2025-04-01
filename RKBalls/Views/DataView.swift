//
//  DataView.swift
//  RKBalls
//
//  Created by Eric Freitas on 3/27/25.
//

import SwiftUI
import RealityKit

struct DataView: View {
    @Binding var entity: Entity?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5, content: {
            Text(entity?.name ?? "..")
        })
    }
}


//#Preview {
//    DataView(infoTarget: <#Entity#>)
//}
