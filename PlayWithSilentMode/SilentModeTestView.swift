import SwiftUI
import AVFoundation
import AudioToolbox
import Combine

let updateSilentState = PassthroughSubject<Bool,Never>()
var startPlayTime: CFTimeInterval = 0

struct ContentView: View {
    
    @State private var isMuted: Bool = false
    @State
    private var updateText = UUID()
    var body: some View {
        VStack {
#if targetEnvironment(simulator)
            Text("Please run this project on a physical device, as the silent mode cannot be correctly detected on the simulator.")
#else
            Text(isMuted ? "Device is in silent mode" : "Device is not in silent mode")
                .transition(.scale)
                .id(updateText)
                .padding()
            Button(action: {
                monitorMute()
            }) {
                Text("Check Silent Mode")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
#endif
           
        }
        .onAppear {
            monitorMute()
        }
        .onReceive(updateSilentState) { silent in
            withAnimation(.smooth) {
                    self.isMuted = silent
                    updateText = UUID()
            }
        }
    }
    
    func monitorMute() {
        // play start time
        startPlayTime = CACurrentMediaTime()
        // play a local audio, length is 0.2s: detection.aiff
        if let soundFileURLRef = Bundle.main.url(forResource: "detection", withExtension: "aiff") {
            var soundFileID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundFileURLRef as CFURL, &soundFileID)
            AudioServicesAddSystemSoundCompletion(soundFileID, nil, nil, { (SSID, clientData) in
                AudioServicesRemoveSystemSoundCompletion(SSID)
                // play complete
                let playDuring = CACurrentMediaTime() - startPlayTime
                if playDuring < 0.1 {
                    updateSilentState.send(true)
                } else {
                    updateSilentState.send(false)
                }
            }, nil)
            AudioServicesPlaySystemSound(soundFileID)
        }
    }
}
