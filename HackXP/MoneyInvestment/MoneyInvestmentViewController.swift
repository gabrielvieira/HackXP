import UIKit
import SceneKit
import ARKit

class MoneyInvestmentViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var segmentSelected: UISegmentedControl!
    @IBOutlet var sceneView: ARSCNView!
    
    // A dictionary of all the current planes being rendered in the scene
    var arr: [String] = ["Poupança\nR$ 796.313,55", "XP Investimentos\nR$ 2.733.962,04"]
    var planes: [UUID:Plane] = [:]
    var cubes: [Money] = []
    var arConfig = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupScene()
        self.setupLights()
        self.setupPhysics()
        self.setupRecognizers()
        // Create a ARSession configuration object we can re-use
        self.arConfig = ARWorldTrackingConfiguration()
        self.arConfig.isLightEstimationEnabled = true
        self.arConfig.planeDetection = .horizontal
        
//        sceneView.debugOptions = [.none]
        // Stop the screen from dimming while we are using the app
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.resetScene()
        self.setLabel(0)
        // Run the view's session
        self.sceneView.session.run(self.arConfig)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func resetScene(){
         self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            
            if node is Money {
                node.removeFromParentNode()
            }
        }
    }
    
    func setLabel(_ index: Int) {
        self.totalLabel.text = arr[index]
    }
    
    @IBAction func didChangeSegment(_ sender: UISegmentedControl) {
        self.resetScene()
        self.setLabel(sender.selectedSegmentIndex)
    }
    
    func setupScene() {
        // Setup the ARSCNViewDelegate - this gives us callbacks to handle new
        // geometry creation
        self.sceneView.delegate = self
        
        // A dictionary of all the current planes being rendered in the scene
        self.planes = [:]
        
        // A list of all the cubes being rendered in the scene
        self.cubes = []
        
        // Make things look pretty
        self.sceneView.antialiasingMode = SCNAntialiasingMode.multisampling4X
        
        // This is the object that we add all of our geometry to, if you want
        // to render something you need to add it here
        let scene = SCNScene()
        self.sceneView.scene = scene
    }
    
    func setupPhysics() {
        // For our physics interactions, we place a large node a couple of meters below the world
        // origin, after an explosion, if the geometry we added has fallen onto this surface which
        // is place way below all of the surfaces we would have detected via ARKit then we consider
        // this geometry to have fallen out of the world and remove it
        let bottomPlane = SCNBox(width: 1500, height: 0.5, length: 1500, chamferRadius: 0)
        let bottomMaterial = SCNMaterial()
        
        // Make it transparent so you can't see it
        bottomMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0)
        bottomPlane.materials = [bottomMaterial]
        let bottomNode = SCNNode(geometry: bottomPlane)
        
        // Place it way below the world origin to catch all falling cubes
        bottomNode.position = SCNVector3Make(0, -10, 0)
        bottomNode.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.kinematic, shape: nil)
        bottomNode.physicsBody?.categoryBitMask = CollisionCategory.bottom.rawValue
        bottomNode.physicsBody?.contactTestBitMask = CollisionCategory.cube.rawValue
        
        let scene = self.sceneView.scene
        scene.rootNode.addChildNode(bottomNode)
        scene.physicsWorld.contactDelegate = self
    }
    
    func setupLights() {
        // Turn off all the default lights SceneKit adds since we are handling it ourselves
        self.sceneView.autoenablesDefaultLighting = false
        self.sceneView.automaticallyUpdatesLighting = false
        
        let env = UIImage(named: "./moneyInvestment.scnassets/Environment/spherical.jpg")
        self.sceneView.scene.lightingEnvironment.contents = env
    }
    
    func setupRecognizers() {
        // Single tap will insert a new piece of geometry into the scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(insertCubeFrom))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Press and hold will open a config menu for the selected geometry
        let materialGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(geometryConfigFrom))
        materialGestureRecognizer.minimumPressDuration = 0.5
        self.sceneView.addGestureRecognizer(materialGestureRecognizer)
        
        // Press and hold with two fingers causes an explosion
        let explodeGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(explodeFrom))
        explodeGestureRecognizer.minimumPressDuration = 1
        explodeGestureRecognizer.numberOfTouchesRequired = 2
        self.sceneView.addGestureRecognizer(explodeGestureRecognizer)
    }
    
    @objc func insertCubeFrom(recognizer: UITapGestureRecognizer) {
        // Take the screen space tap coordinates and pass them to the hitTest method on the ARSCNView instance
        let tapPoint = recognizer.location(in: self.sceneView)
        let result = self.sceneView.hitTest(tapPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        // If the intersection ray passes through any plane geometry they will be returned, with the planes
        // ordered by distance from the camera
        if result.count == 0 {
            return
        }
        
        // If there are multiple hits, just pick the closest plane
        let hitResult = result.first
        
        var count = 30
        
        if self.segmentSelected.selectedSegmentIndex == 1 {
            count = 150
        }
        
        for n in 0..<count {
            self.insertCube(hitResult: hitResult!)
        }
    }
    
    @objc func explodeFrom(recognizer: UITapGestureRecognizer) {
        if recognizer.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // a plane.
        let holdPoint = recognizer.location(in: self.sceneView)
        let result = self.sceneView.hitTest(holdPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if result.count == 0 {
            return
        }
        
        let hitResult = result.first
        self.explode(hitResult: hitResult!)
    }
    
    @objc func geometryConfigFrom(recognizer: UITapGestureRecognizer) {
        if recognizer.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // any 3D geometry in the scene, if so we will open a config menu for that
        // geometry to customize the appearance
        
        let holdPoint = recognizer.location(in: self.sceneView)
        let result = self.sceneView.hitTest(holdPoint, options: [SCNHitTestOption.boundingBoxOnly: true, SCNHitTestOption.firstFoundOnly : true])
        if result.count == 0 {
            return
        }
        
        let hitResult = result.first
        let node = hitResult?.node
    }
    
    func hidePlanes() {
        for (planeID, _) in self.planes {
            self.planes[planeID]?.hide()
        }
    }
    
    func disableTracking(disabled: Bool) {
        // Stop detecting new planes or updating existing ones.
        
        if disabled {
            self.arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.init(rawValue: 0)
        } else {
            self.arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        }
        
        self.sceneView.session.run(self.arConfig)
    }
    
    func explode(hitResult: ARHitTestResult) {
        // For an explosion, we take the world position of the explosion and the position of each piece of geometry
        // in the world. We then take the distance between those two points, the closer to the explosion point the
        // geometry is the stronger the force of the explosion.
        
        // The hitResult will be a point on the plane, we move the explosion down a little bit below the
        // plane so that the goemetry fly upwards off the plane
        let explosionYOffset: Float = 0.1
        
        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y.advanced(by: -explosionYOffset), hitResult.worldTransform.columns.3.z)
        
        // We need to find all of the geometry affected by the explosion, ideally we would have some
        // spatial data structure like an octree to efficiently find all geometry close to the explosion
        // but since we don't have many items, we can just loop through all of the current geometry
        for cubeNode in self.cubes {
            // The distance between the explosion and the geometry
            var distance = SCNVector3Make(cubeNode.worldPosition.x - position.x, cubeNode.worldPosition.y - position.y, cubeNode.worldPosition.z - position.z)
            let length: Float = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            
            // Set the maximum distance that the explosion will be felt, anything further than 2 meters from
            // the explosion will not be affected by any forces
            let maxDistance: Float = 1
            var scale = max(0, maxDistance - length)
            
            // Scale the force of the explosion
            scale = scale * scale * 1
            
            // Scale the distance vector to the appropriate scale
            distance.x = distance.x / length * scale
            distance.y = distance.y / length * scale
            distance.z = distance.z / length * scale
            
            // Apply a force to the geometry. We apply the force at one of the corners of the cube
            // to make it spin more, vs just at the center
            cubeNode.childNodes.first?.physicsBody?.applyForce(distance, at: SCNVector3Make(0.01, 0.01, 0.01), asImpulse: false)
        }
    }
    
    func insertCube(hitResult: ARHitTestResult) {
        // We insert the geometry slightly above the point the user tapped, so that it drops onto the plane
        // using the physics engine
        let insertionYOffset: Float = 0.5
        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y.advanced(by: insertionYOffset), hitResult.worldTransform.columns.3.z)
        
        let cube = Money(position)
        
//        let scnp = SCNParticleSystem(named: "Fire.scnp", inDirectory: nil)
//        let fireNode = SCNNode()
//        fireNode.addParticleSystem(scnp!)
//        fireNode.position = cube.position
//        fireNode.scale = SCNVector3(0.001, 0.001, 0.001)
//        sceneView.scene.rootNode.addChildNode(fireNode)
        self.cubes.append(cube)
        self.sceneView.scene.rootNode.addChildNode(cube)
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Here we detect a collision between pieces of geometry in the world, if one of the pieces
        // of geometry is the bottom plane it means the geometry has fallen out of the world. just remove it
        guard let physicsBodyA = contact.nodeA.physicsBody, let physicsBodyB = contact.nodeB.physicsBody else {
            return
        }
        
        let categoryA = CollisionCategory.init(rawValue: physicsBodyA.categoryBitMask)
        let categoryB = CollisionCategory.init(rawValue: physicsBodyB.categoryBitMask)
        
        let contactMask: CollisionCategory? = [categoryA, categoryB]
        
        if contactMask == [CollisionCategory.bottom, CollisionCategory.cube] {
            if categoryA == CollisionCategory.bottom {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let estimate = self.sceneView.session.currentFrame?.lightEstimate else {
            return
        }
        
        // A value of 1000 is considered neutral, lighting environment intensity normalizes
        // 1.0 to neutral so we need to scale the ambientIntensity value
        let intensity = estimate.ambientIntensity / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity*1.5
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !anchor.isKind(of: ARPlaneAnchor.classForCoder()) {
            return
        }
        
        // When a new plane is detected we create a new SceneKit plane to visualize it in 3D
        let plane = Plane(anchor: anchor as! ARPlaneAnchor, isHidden: false, withMaterial: Plane.currentMaterial()!)
        planes[anchor.identifier] = plane
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        
        // When an anchor is updated we need to also update our 3D geometry too. For example
        // the width and height of the plane detection may have changed so we need to update
        // our SceneKit geometry to match that
        plane.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Nodes will be removed if planes multiple individual planes that are detected to all be
        // part of a larger plane are merged.
        self.planes.removeValue(forKey: anchor.identifier)
    }
}
