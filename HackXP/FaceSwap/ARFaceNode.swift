//
//  ARFaceNode.swift
//  ARKit-Sampler
//
//  Created by Shuichi Tsutsumi on 2017/12/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class MaskNode: SCNNode {
    
    var index = 0
    var width: CGFloat = 0.27
    var height: CGFloat = 0.27
    
    init(image: String) {
        super.init()
        
        if image == "chefe" {
            self.width = 0.23
            self.height = 0.27
        }
        
        let image = UIImage(named: image)
        let plane = SCNPlane(width: self.width, height: height)
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.isDoubleSided = true
        geometry = plane
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class ARFaceNode: SCNNode {

    init(device: MTLDevice, color: UIColor = .red) {
        
        let program = SCNProgram()
        program.vertexFunctionName = "scnVertexShader"
        program.fragmentFunctionName = "scnFragmentShader"

    
//
        let faceGeometry = ARSCNFaceGeometry(device: device)
//        faceGeometry.?.firstMaterial?.transparency = 0.0
        if let material = faceGeometry?.firstMaterial {
            material.transparency = 0.0
        }
        
        super.init()
        self.geometry = faceGeometry
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with faceAnchor: ARFaceAnchor) {
        guard let faceGeometry = geometry as? ARSCNFaceGeometry else {return}
        faceGeometry.update(from: faceAnchor.geometry)
    }
}

extension SCNNode {
    
    func findFaceNode() -> ARFaceNode? {
        for childNode in childNodes {
            guard let faceNode = childNode as? ARFaceNode else { continue }
            return faceNode
        }
        return nil
    }
}
