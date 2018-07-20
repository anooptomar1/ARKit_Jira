//
//  ViewController.swift
//  JiraTicketAR
//
//  Created by Zach Eriksen on 7/20/18.
//  Copyright © 2018 cri. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// State of the view
enum State: String {
    case details = "Details"
    case description = "Description"
    case time = "Time"
}

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    // State of the buttons
    var currentState: State = .details
    // Sticky note color
    let stickyColor: UIColor = UIColor(red: 1, green: 40 / 255, blue: 85 / 255, alpha: 0.75)
    // Real size of the sticky note
    var size: CGSize!
    // Node attached to the sticky note
    var planeNode: SCNNode!
    // Buttons
    var detailsButton: SCNNode!
    var descriptionButton: SCNNode!
    var timeButton: SCNNode!
    // Custom views
    var detailsNode: SCNNode! = SCNNode()
    var descriptionNode: SCNNode! = SCNNode()
    var timeNode: SCNNode! = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
    }
    
    // MARK: Private Helpers
    // Create a label
    private func createLabelView(forState state: State) -> UILabel {
        let frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 100))
        let label = UILabel(frame: frame)
        
        label.text = state.rawValue
        label.textAlignment = .center
        label.layer.borderColor = currentState == state ? UIColor.black.cgColor : stickyColor.cgColor
        label.textColor = currentState == state ? .black : stickyColor
        label.layer.borderWidth = 4
        label.layer.cornerRadius = 8
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.backgroundColor = currentState == state ? stickyColor : .black
        return label
    }
    
    // Create the SceneKit SCNNode that will act as our button
    private func createButtonNode(forState state: State) -> SCNNode {
        let buttonView = SCNBox(width: 0.02, height: 0.0001, length: 0.01, chamferRadius: 0)
        buttonView.firstMaterial?.diffuse.contents = createLabelView(forState: state)
        let buttonNode = SCNNode(geometry: buttonView)
        buttonNode.eulerAngles.x = -.pi / 2
        return buttonNode
    }
    
    // Create the details button
    func createDetailsButton() {
        if let node = detailsButton {
            node.removeFromParentNode()
        }
        detailsButton = createButtonNode(forState: .details)
        detailsButton.position.y = -0.0475
        detailsButton.position.x = -0.0275
        planeNode.addChildNode(detailsButton)
    }
    
    // Create the description button
    func createDescriptionButton() {
        if let node = descriptionButton {
            node.removeFromParentNode()
        }
        descriptionButton = createButtonNode(forState: .description)
        descriptionButton.position.y = -0.0475
        descriptionButton.eulerAngles.x = -.pi / 2
        planeNode.addChildNode(descriptionButton)
    }
    
    // Create the time buttton
    func createTimeButton() {
        if let node = timeButton {
            node.removeFromParentNode()
        }
        timeButton = createButtonNode(forState: .time)
        timeButton.eulerAngles.x = -.pi / 2
        timeButton.position.y = -0.0475
        timeButton.position.x = 0.0275
        planeNode.addChildNode(timeButton)
    }
    
    // In viewWillAppear prepare the images we want to track
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()

        guard let images = ARReferenceImage.referenceImages(inGroupNamed: "Images", bundle: Bundle.main) else {
            fatalError("No Images (Make sure the folder name is `Images`)")
        }
        configuration.trackingImages = images
        configuration.maximumNumberOfTrackedImages = images.count
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Once we have found an Image give it a ARImageAnchor to attach the SCNNodes to
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                                 height: imageAnchor.referenceImage.physicalSize.height)
            size = imageAnchor.referenceImage.physicalSize
            plane.firstMaterial?.diffuse.contents = UIColor.clear
            planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            update()
            
            node.addChildNode(planeNode)
        }
        return node
    }
    
    // Used for when the use interacts with the buttons
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        if touch.view == sceneView {
            let touchLocation: CGPoint = touch.location(in: sceneView)
            guard let result = sceneView.hitTest(touchLocation, options: nil).first else {
                return
            }
            let node = result.node
            
            switch node {
            case detailsButton: currentState = .details
            case descriptionButton: currentState = .description
            case timeButton: currentState = .time
            default: print("Not a button!")
            }
            update()
        }
    }
    
    // Handles updating the current view and button
    func update() {
        switch currentState {
        case .details: showDetails()
        case .description: showDescription()
        case .time: showTime()
        }
        createDescriptionButton()
        createTimeButton()
        createDetailsButton()
    }
    
    // Shows the details view
    func showDetails() {
        createDetailsViewNode()
        descriptionNode.removeFromParentNode()
        timeNode.removeFromParentNode()
    }
    
    // Shows the description view
    func showDescription() {
        createDescriptionViewNode()
        detailsNode.removeFromParentNode()
        timeNode.removeFromParentNode()
    }
    
    // Shows the time view
    func showTime() {
        createTimeTrackingViewNode()
        detailsNode.removeFromParentNode()
        descriptionNode.removeFromParentNode()
    }
}
// MARK: Static Views
extension ViewController {
    fileprivate func createDetailsViewNode() {
        if let node = detailsNode {
            node.removeFromParentNode()
        }
        let frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 500))
        let textView = UITextView(frame: frame)
        
        textView.backgroundColor = stickyColor
        textView.font = UIFont.boldSystemFont(ofSize: 30)
        textView.text =
        """
        \tType: BUG
        \tPriority: Highest
        \tStatus: DEV-ACTIVE
        \tFlags: None
        
        Assignee: Zach
        Reporter: Dehn
        
        Affects Version/s: None
        Component/s: iOS
        Labels: None
        Budget: MPP
        Fix Version/s: RB2_D6
        """
        let boxView = SCNBox(width: size.width, height: 0.0001, length: size.height, chamferRadius: 0)
        boxView.firstMaterial?.diffuse.contents = textView
        detailsNode = SCNNode(geometry: boxView)
        detailsNode.eulerAngles.x = -.pi / 2
        detailsNode.position.y = Float(-size.height - 0.015)
        
        planeNode.addChildNode(detailsNode)
    }
    
    fileprivate func createDescriptionViewNode() {
        if let node = descriptionNode {
            node.removeFromParentNode()
        }
        // Create a UITextView
        let frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 500))
        let textView = UITextView(frame: frame)
        
        textView.backgroundColor = stickyColor
        textView.font = UIFont.boldSystemFont(ofSize: 30)
        textView.isScrollEnabled = true
        textView.text =
        """
        QA Note: Attempted to replicate with 1.2.0 (64) and 1.2.0 (63) in QA Environment and was unable to reproduce.
        
        ALM Priority: Blocker
        
        iOS ONLY
        iPhone 7+;iPhone X
        
        Expected:
        When selecting "Contact" on the Login screen the Contact page displays. (also from the Main Menu)
        
        Actual:
        When selecting "Contact" on the Login screen the App crashes.
        
        Steps to recreate:
        launch app
        Select Contact
        confirm app crashes
        
        **Note: i was successfully able to log in. The app only crashes when you select "Contact"
        
        """
        let boxView = SCNBox(width: size.width, height: 0.0001, length: size.height, chamferRadius: 0)
        boxView.firstMaterial?.diffuse.contents = textView
        descriptionNode = SCNNode(geometry: boxView)
        descriptionNode.eulerAngles.x = -.pi / 2
        descriptionNode.position.y = Float(-size.height - 0.015)
        
        planeNode.addChildNode(descriptionNode)
    }
    
    fileprivate func createTimeTrackingViewNode() {
        if let node = timeNode {
            node.removeFromParentNode()
        }
        let frame = CGRect(origin: .zero, size: CGSize(width: 500, height: 500))
        let textView = UITextView(frame: frame)
        
        textView.backgroundColor = stickyColor
        textView.font = UIFont.boldSystemFont(ofSize: 30)
        textView.text =
        """
        Estimated Time: 16 hours
        Remaining Time: 10 hours
        Logged Time: 6 hours
        """
        let boxView = SCNBox(width: size.width, height: 0.0001, length: size.height, chamferRadius: 0)
        boxView.firstMaterial?.diffuse.contents = textView
        timeNode = SCNNode(geometry: boxView)
        timeNode.eulerAngles.x = -.pi / 2
        timeNode.position.y = Float(-size.height - 0.015)
        
        planeNode.addChildNode(timeNode)
    }
}
