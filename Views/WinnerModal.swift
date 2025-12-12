//
//  WinnerModal.swift
//  Accountability Buddy
//
//  Created for winner/loser message display
//

import SwiftUI

struct WinnerModal: View {
    let goalName: String
    let buddyName: String
    let isWinner: Bool
    let winnersPrize: String?
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // Modal content
            VStack(spacing: 20) {
                // Trophy or sad icon
                Image(systemName: isWinner ? "trophy.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isWinner ? .orange : .red)
                
                // Winner/Loser message
                Text(isWinner ? "You Won!" : "You Lost")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isWinner ? .orange : .red)
                
                // Goal name and buddy name
                Text(isWinner ? 
                     "You won the \"\(goalName)\" goal against \(buddyName)!" :
                     "You lost the \"\(goalName)\" goal against \(buddyName).")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Challenge stakes (only show if winner and stakes exist)
                if isWinner, let prize = winnersPrize, !prize.isEmpty {
                    VStack(spacing: 8) {
                        Text("Challenge Stakes:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(prize)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Close button
                Button(action: {
                    onClose()
                }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isWinner ? Color.orange : Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 30)
            .frame(width: 320)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}

