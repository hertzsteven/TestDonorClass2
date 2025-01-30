//
//  BarcodeScannerView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 1/29/25.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIViewController()
        let session = AVCaptureSession()
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return controller
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return controller
        }
        
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        output.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr, .code128]
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = controller.view.layer.bounds
        controller.view.layer.addSublayer(videoPreviewLayer)
        
        session.startRunning()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, presentationMode: presentationMode)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedCode: String
        var presentationMode: Binding<PresentationMode>
        
        init(scannedCode: Binding<String>, presentationMode: Binding<PresentationMode>) {
            self._scannedCode = scannedCode
            self.presentationMode = presentationMode
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let stringValue = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.scannedCode = stringValue
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
