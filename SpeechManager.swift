
import UIKit
import Speech

class SpeechManager: NSObject, SFSpeechRecognizerDelegate
{
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine:AVAudioEngine? = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var voiceInteractorSemaphor = true
    private var listeningSempahor = true
    private var voiceInputMessage = String()
    private var locName = String()
     private var locPlacemark = String()
    private var locationName:String
    {
        set
        {
            locName = newValue
            voiceOutput(message: "Enter the placemark")
            sleep(2)
            voiceInput(isLocationSave: true)
        }
        get
        {
            return locName
        }
    }
    private var locationPlacemark:String
    {
        set
        {
          locPlacemark = newValue
        }
        get
        {
            return locPlacemark
        }
    }
    
    
    override init()
    {
        super.init()
        setupSpeechKit()
    }
    
     func setupSpeechKit()
    {
        speechRecognizer!.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        }
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
            let audioSession = AVAudioSession.sharedInstance()
            do
            {
                try audioSession.setCategory(.playAndRecord, mode: .default)
                try audioSession.setMode(AVAudioSession.Mode.measurement)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                //try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
                
            } catch
                
            {
                    
            }
        
    }
    
    func voiceInput(isLocationSave:Bool=false)
    {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        let inputNode = audioEngine!.inputNode
        recognitionRequest.shouldReportPartialResults = true
         recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            if result != nil
            {
                if(!isLocationSave)
                {
                    self.voiceInputMessage = (result?.bestTranscription.formattedString)!
                    if(self.listeningSempahor)
                    {
                        self.listeningSempahor = false
                        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.voiceInputAction), userInfo: nil, repeats: false)
                    }
                }
                else
                {
                    if(self.locationName.isEmpty)
                    {
                      self.locationName = (result?.bestTranscription.formattedString)!
                    }
                    else
                    {
                      self.locationPlacemark = (result?.bestTranscription.formattedString)!
                    }
                }
                
            }
            if error != nil  {
                self.audioEngine!.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
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
    }
    
    @objc func voiceInputAction()
    {
        voiceInputMessage = voiceInputMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        print(" final "+voiceInputMessage)
      
        if(voiceInputMessage == "Let's walk")
        {
            AppDelegate.primeDelegate!.letsWalk()
        }
        else if(voiceInputMessage == "Where am I")
        {
            AppDelegate.primeDelegate!.whereAmI()
        }
        else
        {
            if(voiceInputMessage.count<10)
            {
                return
            }
            let index = voiceInputMessage.index(voiceInputMessage.startIndex, offsetBy: 10)
            let isTakeMeCommand = voiceInputMessage[..<index]
            print(String(isTakeMeCommand))
            //let destination = voiceInputMessage.substring(from: index)
            let destination = voiceInputMessage[index...]
            print(String(destination))
            if (isTakeMeCommand == "Take me to")
            {
                AppDelegate.primeDelegate!.filterLocationList(filterInput: String(destination))
            }
        }
    }
    
    func awakeVoiceInteractor()
    {
        if(voiceInteractorSemaphor)
        {
            voiceInteractorSemaphor = false;
            _ = Timer.scheduledTimer(withTimeInterval: 20, repeats: false)
            { timer in
                self.voiceInteractorSemaphor = true
            }
            voiceOutput(message: Constants.awakeMessage)
            sleep(2)
            voiceInput()
        }
    }
    
    func voiceOutput(message:String)
    {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.3
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    func inputsToSaveLocation()->(String,String)
    {
        voiceOutput(message: "What is the location name")
        sleep(2)
        voiceInput(isLocationSave: true)
        return (locationName,locationPlacemark)
    }
}

