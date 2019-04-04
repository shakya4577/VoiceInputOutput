import UIKit
import Speech

class ViewController: UIViewController
{

    @IBOutlet weak var txtView: UITextView!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine:AVAudioEngine? = AVAudioEngine()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        txtView.layer.borderWidth = 2.0
        txtView.layer.cornerRadius = 10.0
        txtView.layer.borderColor = UIColor.lightGray.cgColor
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
        resignFirstResponder()
    }

    @IBAction func btnListen(_ sender: Any)
    {
        startListening()
    }
    
    @IBAction func btnSpeak(_ sender: Any)
    {
        startSpeaking()
    }
    
    func startListening()
    {
        let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Oops..Couldn't create instane of SFSpeechAudioBufferRecognitionRequest object")
        }
        
        let inputNode = audioEngine!.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine!.prepare()
        do {
            try audioEngine!.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            if result != nil
            {
                self.txtView.text =  result?.bestTranscription.formattedString
            }
            if error != nil  {
                self.audioEngine!.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
    }
    
    func startSpeaking()
    {
        let utterance = AVSpeechUtterance(string: txtView.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.3
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
}

