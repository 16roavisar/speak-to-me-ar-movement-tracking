import UIKit
import Speech
import AVKit
import ARKit

class ViewController: UIViewController {

    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Outlets
    //------------------------------------------------------------------------------

    @IBOutlet weak var btnStart             : UIButton!
    @IBOutlet weak var lblText              : UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    @IBOutlet weak var meshSwitch: UISwitch!
    
    var bottomText = ""
    
    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Variables
    //------------------------------------------------------------------------------

    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()


    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Action Methods
    //------------------------------------------------------------------------------

    @IBAction func btnStartSpeechToText(_ sender: UIButton) {

        if audioEngine.isRunning {
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.btnStart.isEnabled = false
            self.btnStart.setTitle("Start Recording", for: .normal)
        } else {
            self.startRecording()
            self.btnStart.setTitle("Stop Recording", for: .normal)
        }
    }


    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Custom Methods
    //------------------------------------------------------------------------------

    func setupSpeech() {

        self.btnStart.isEnabled = false
        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                fatalError()
            }

            OperationQueue.main.addOperation() {
                self.btnStart.isEnabled = isButtonEnabled
            }
        }
    }

    //------------------------------------------------------------------------------

    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {

                self.lblText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.btnStart.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        self.lblText.text = "Say something, I'm listening!"
    }


    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- View Life Cycle Methods
    //------------------------------------------------------------------------------

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported by this device")
        }
        
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
       
        var device: MTLDevice!
        device = MTLCreateSystemDefaultDevice()
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.fillMode = .lines
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
           /*
           Tells the delegate that a SceneKit node's properties have been updated to match the current state of its corresponding anchor.
           renderer : The ARSCNView object rendering the scene
           node : The updated SceneKit node
           anchor : The AR anchor corresponding to the node
            */
        
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
                   faceGeometry.update(from: faceAnchor.geometry)
               // everytime the mesh detects an update
               
                   readMyFace(anchor: faceAnchor)
                   // run readMyFace function
               
                   DispatchQueue.main.async { self.bottomLabel.text = self.bottomText }
                   // Update the text on the main thread
           }
        
       }

       func readMyFace(anchor: ARFaceAnchor) {
           // function that takes an ARFaceAnchor in as a parameter
           
           let mouthSmileLeft = anchor.blendShapes[.mouthSmileLeft]
           let mouthSmileRight = anchor.blendShapes[.mouthSmileRight]
           let mouthRight = anchor.blendShapes[.mouthLeft]
           let mouthLeft = anchor.blendShapes[.mouthRight]
           let cheekPuff = anchor.blendShapes[.cheekPuff]
           let tongueOut = anchor.blendShapes[.tongueOut]
           let jawLeft = anchor.blendShapes[.jawLeft]
           let jawRight = anchor.blendShapes[.jawRight]
           let jawOpen = anchor.blendShapes[.jawOpen]
           let eyeSquintLeft = anchor.blendShapes[.eyeSquintLeft]
           let eyeSquintRight = anchor.blendShapes[.eyeSquintRight]
           // Define different anchors utilizing classes in the imported kit
           
           self.bottomText = "You are still faced"
           // when this function is running I want to signal to the user that the function is reacting
        
           if ((mouthSmileLeft?.decimalValue ?? 0.0) + (mouthSmileRight?.decimalValue ?? 0.0)) > 0.8 {
               self.bottomText = "You are smiling"
               print("You are smiling")
           }
           // smiling
           if mouthLeft?.decimalValue ?? 0.0 > 0.4 {
               self.bottomText = "You are moving your mouth to the left"
               print("You are moving your mouth to the left")
           }
          // mouth right
           if mouthRight?.decimalValue ?? 0.0 > 0.4 {
               self.bottomText = "You are moving your mouth to the right"
               print("You are moving your mouth to the right")
           }
          // mouth right
           if cheekPuff?.decimalValue ?? 0.0 > 0.4 {
               self.bottomText = "You are puffing your cheeks"
               print("You are puffing your cheeks")
           }
          // puffy cheeks
           if tongueOut?.decimalValue ?? 0.0 > 0.1 {
               self.bottomText = "You are sticking your tongue out"
               print("You are sticking your tongue out")
           }
           // tongue out
           if jawLeft?.decimalValue ?? 0.0 > 0.1 {
               self.bottomText = "You are moving your jaw to the left"
               print("You are moving your jaw to the left")
           }
           // left jaw
           if jawRight?.decimalValue ?? 0.0 > 0.1 {
               self.bottomText = "You are moving your jaw to the right"
               print("You are moving your jaw to the right")
           }
           // right jaw
           if jawOpen?.decimalValue ?? 0.0 > 0.7 {
               self.bottomText = "Your jaw is open"
               print("Your jaw is open")
           }
           // jaw open
           if eyeSquintLeft?.decimalValue ?? 0.0 > 0.2 {
               self.bottomText = "You are squinting your left eye"
               print("You are squinting your left eye")
           }
           // left eye squint
           if eyeSquintRight?.decimalValue ?? 0.0 > 0.2 {
               self.bottomText = "You are squinting your right eye"
               print("You are squinting your right eye")
           }
           // right eye squint
           
           // different if statements to update the bottomText based off the facial expression
           //print(lblText.text)
       }
    
    
}


//------------------------------------------------------------------------------
// MARK:-
// MARK:- SFSpeechRecognizerDelegate Methods
//------------------------------------------------------------------------------

extension ViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.btnStart.isEnabled = true
        } else {
            self.btnStart.isEnabled = false
        }
    }
}
