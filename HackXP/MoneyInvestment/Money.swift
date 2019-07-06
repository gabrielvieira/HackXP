import UIKit
import ARKit

var moneyValues = ["Bolo50Reais","Bolo100Reais"]

class Money: SCNNode {
    init(_ position: SCNVector3) {
        super.init()
        let scene = SCNScene(named: "moneyInvestment.scnassets/main.scn")!
        let node = scene.rootNode.childNode(withName: "money", recursively: true)!
        let material = SCNMaterial()
//        material.lightingModel = SCNMaterial.LightingModel.physicallyBased
        material.name = "MoneyImage"
        material.diffuse.contents = UIImage(named: moneyValues[Int.random(in: 0...1)])
        node.geometry?.materials = [material]
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.mass = 100.0
        node.physicsBody?.categoryBitMask = CollisionCategory.cube.rawValue
        node.position = position
        
        self.addChildNode(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
