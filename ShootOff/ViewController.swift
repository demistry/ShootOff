//
//  ViewController.swift
//  ShootOff
//
//  Created by David Ilenwabor on 24/12/2018.
//  Copyright © 2018 David Ilenwabor. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate , ARSessionDelegate{

    @IBOutlet var sceneView: ARSCNView!
    
    var trackingNode : SCNNode?
    var smoothSurface = false
    var tracking = true
    
    var directionalLight : SCNNode?
    var ambientLight : SCNNode?
    var container : SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard tracking else{
            return
        }
        let hitTest = sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
        guard let result = hitTest.first else{
            return
        }
        let translation = SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
        
        if trackingNode == nil{
            let plane = SCNPlane(width: 0.15, height: 0.15)
            plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
            plane.firstMaterial?.isDoubleSided = true
            trackingNode = SCNNode(geometry: plane)
            trackingNode?.eulerAngles.x = -.pi * 0.5
            sceneView.scene.rootNode.addChildNode(self.trackingNode!)
            smoothSurface = true
        }
        trackingNode?.position = position
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tracking{
            guard smoothSurface else{
                return
            }
            let trackingPosition = trackingNode!.position
            trackingNode?.removeFromParentNode()
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)
            container?.position = trackingPosition
            container?.isHidden = false
            
            ambientLight = container?.childNode(withName: "ambient", recursively: false)
            directionalLight = container?.childNode(withName: "directional", recursively: false)
            tracking = false
        } else{
            guard let frame = sceneView.session.currentFrame else{
                return
            }
            let camMatrix = SCNMatrix4(frame.camera.transform)
            let direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 10.0, -camMatrix.m33 * 5.0)
            let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
            
            let ball = SCNSphere(radius: 0.05)
            ball.firstMaterial?.diffuse.contents = UIColor.blue
            ball.firstMaterial?.emission.contents = UIColor.blue
            let ballNode = SCNNode(geometry: ball)
            ballNode.position = position
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.categoryBitMask = 3
            ballNode.physicsBody?.contactTestBitMask = 1
            sceneView.scene.rootNode.addChildNode(ballNode)
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.removeFromParentNode()]))
            ballNode.physicsBody?.applyForce(direction, asImpulse: true)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let light = frame.lightEstimate else{
            return
        }
        guard !tracking else{
            return
        }
        ambientLight?.light?.intensity = light.ambientIntensity * 0.4
        directionalLight?.light?.intensity = light.ambientIntensity
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/game_scene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.delegate = self

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
