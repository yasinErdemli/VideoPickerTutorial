//
//  ContentView.swift
//  VideoPickerTutorial
//
//  Created by Yasin Erdemli on 13.04.2023.
//

import SwiftUI
import PhotosUI
import AVKit

struct ContentView: View {
    @State private var showVideoPicker: Bool = false
    @State private var selectedVideo: PhotosPickerItem?
    @State private var isVideoProcessing: Bool = true
    @State private var pickedMovieURL: URL?
    var body: some View {
        VStack {
            ZStack {
                if let pickedMovieURL {
                    VideoPlayer(player: .init(url: pickedMovieURL))
                }
                if isVideoProcessing {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            Button("pick video") {
                showVideoPicker.toggle()
            }
            
            Button("remove picked video") {
                deleteFile()
            }
        }
        .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideo, matching: .videos)
        .onChange(of: selectedVideo) { newValue in
            if let newValue {
                Task {
                    do {
                        isVideoProcessing = true
                        let pickedMovie = try await newValue.loadTransferable(type: VideoPickerTransferable.self)
                        isVideoProcessing = false
                        pickedMovieURL = pickedMovie?.videoURL
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .padding()
    }
    
    func deleteFile() {
        do {
            if let pickedMovieURL {
                try FileManager.default.removeItem(at: pickedMovieURL)
                self.pickedMovieURL = nil
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct VideoPickerTransferable: Transferable {
    let videoURL: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { exportingFile in
            return .init(exportingFile.videoURL)
        } importing: { ReceivedTransferredFile in
            let originalFile = ReceivedTransferredFile.file
            let copiedFile = URL.documentsDirectory.appending(path: "videoPicker.mov")
            if FileManager.default.fileExists(atPath: copiedFile.path()) {
                try FileManager.default.removeItem(at: copiedFile)
            }
            try FileManager.default.copyItem(at: originalFile, to: copiedFile)
            return .init(videoURL: copiedFile)
        }

    }
}
