//
//  MoneyAirplaneViewController.swift
//  HackXP
//
//  Created by Ezequiel França on 06/07/19.
//  Copyright © 2019 Gabriel vieira. All rights reserved.
//

import UIKit
import ARKit

private class PeopleNode: SCNNode {
    
    var index = 0
    
    init(width: CGFloat = 0.27, height: CGFloat = 0.27) {
        super.init()
        let image = UIImage(named: "silvo")
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.isDoubleSided = true
        geometry = plane
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PhyisicsViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var hitLabel: UILabel! {
        didSet {
            hitLabel.isHidden = true
        }
    }
    
    let defaultConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }()
    
    lazy var boxNode: SCNNode = {
        let cylinder = SCNCylinder(radius: 1, height: 1)
        let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.01)
        box.firstMaterial?.diffuse.contents = UIColor.red
        let node = SCNNode(geometry: box)
        node.name = "box"
        node.position = SCNVector3Make(0, 0, -3)
        
        // add PhysicsShape
        let shape = SCNPhysicsShape(geometry: box, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        node.physicsBody?.isAffectedByGravity = false
        
        return node
    }()
    
    func insertImage(image: UIImage, width: CGFloat = 0.3, height: CGFloat = 0.3) -> SCNNode {
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial!.diffuse.contents = image
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.session.run(defaultConfiguration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func setup() {
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        SilvioPlayer().playSound()
        self.setup()
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let scene = SCNScene(named: "silvio.scnassets/paper_airplane.scn")!
        
        let ball = SCNSphere(radius: 1.0)
        ball.firstMaterial?.diffuse.contents = UIColor.blue
        
        let node = scene.rootNode//SCNNode(geometry: ball)
        node.name = "ball"
        node.position = SCNVector3Make(0, 0.1, 0)
        
        // add PhysicsShape
        let shape = SCNPhysicsShape(geometry: ball, options: nil)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        node.physicsBody?.contactTestBitMask = 1
        node.physicsBody?.isAffectedByGravity = false
        
        if let camera = sceneView.pointOfView {
            node.position = camera.position
            
            let toPositionCamera = SCNVector3Make(0, 0, -3)
            let toPosition = camera.convertPosition(toPositionCamera, to: nil)
            
            let move = SCNAction.move(to: toPosition, duration: 1.5)
            let silvio = PeopleNode(width: 0.799, height: 0.316)
            silvio.position = SCNVector3Make(0, 0, -2)
            sceneView.scene.rootNode.addChildNode(silvio)
            move.timingMode = .easeInEaseOut
            node.runAction(move) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    node.removeFromParentNode()
                }
            }
        }
        
        sceneView.scene.rootNode.addChildNode(scene.rootNode)
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
        let currentTransform = frame.camera.transform
       // doSomething(with: currentTransform)
        setup()
    }
    
}

extension PhyisicsViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if (nodeA.name == "box" && nodeB.name == "ball")
            || (nodeB.name == "box" && nodeA.name == "ball") {
            
            DispatchQueue.main.async {
                self.hitLabel.text = "MA OEE!! HIHIHI!!"
                self.hitLabel.sizeToFit()
                self.hitLabel.isHidden = false
                
                // Vibration
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.hitLabel.isHidden = true
                }
            }
        }
    }
}
