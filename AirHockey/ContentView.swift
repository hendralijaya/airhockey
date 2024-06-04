//
//  ContentView.swift
//  AirHockey
//
//  Created by hendra on 02/06/24.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            Text("Air Hockey")
                .font(.largeTitle)
                .padding()
            
            if viewModel.isConnected {
                gameView
            } else {
                connectionView
            }
        }
        .sheet(isPresented: $viewModel.showBrowser) {
            if let browser = viewModel.browser {
                BrowserViewControllerWrapper(browser: browser)
            }
        }
    }
    
    var connectionView: some View {
        VStack {
            Button("Start Advertising") {
                viewModel.startAdvertising()
            }
            .padding()
            
            Button("Start Browsing") {
                viewModel.startBrowsing()
            }
            .padding()
        }
    }
    
    var gameView: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw the game field
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 300, height: 500)
                
                // Draw the puck
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .position(viewModel.gameState!.puckPosition)
                
                // Draw mallet 1 (red)
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)
                    .position(viewModel.gameState!.mallet1Position)
                
                // Draw mallet 2 (blue)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .position(viewModel.gameState!.mallet2Position)
            }
            .gesture(DragGesture().onChanged { value in
                let newPosition = clampedPosition(for: value.location, in: geometry.size, for: viewModel.localMallet)
                viewModel.updateMalletPosition(newPosition)
            })
        }
        .frame(width: 300, height: 500)
    }
    
    func clampedPosition(for position: CGPoint, in size: CGSize, for mallet: Mallet) -> CGPoint {
        let malletRadius: CGFloat = 30 // Half of the mallet's width/height (60/2)
        let minY: CGFloat = mallet == .red ? size.height / 2 + malletRadius : malletRadius
        let maxY: CGFloat = mallet == .red ? size.height - malletRadius : size.height / 2 - malletRadius
        let minX: CGFloat = malletRadius
        let maxX: CGFloat = size.width - malletRadius
        
        let clampedX = max(min(position.x, maxX), minX)
        let clampedY = max(min(position.y, maxY), minY)
        
        return CGPoint(x: clampedX, y: clampedY)
    }
}

struct BrowserViewControllerWrapper: UIViewControllerRepresentable {
    var browser: MCBrowserViewController
    
    func makeUIViewController(context: Context) -> MCBrowserViewController {
        return browser
    }
    
    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {}
}

#Preview {
    ContentView()
}

