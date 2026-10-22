//
//  TypesAndTreatmentView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

// MARK: - Stroke Types
struct StrokeType: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let summary: String
    let details: String
}

struct TypesView: View {
    // Data with detailed descriptions and sources
    let types: [StrokeType] = [
        StrokeType(
            name: "Ischemic",
            icon: "🩸",
            summary: "Most common (~87%)",
            details: "Ischemic strokes occur when a blood clot blocks an artery in the brain, cutting off blood flow.\n\n• Accounts for about 87% of all strokes.\n• Rapid treatment with clot‑dissolving medication (tPA) within 3–4.5 hours can significantly improve outcomes.\n\nSource: American Stroke Association (stroke.org)"
        ),
        StrokeType(
            name: "Hemorrhagic",
            icon: "🧠",
            summary: "Less common (~13%)",
            details: """
        Hemorrhagic strokes occur when a weakened blood vessel ruptures and bleeds into the brain, increasing intracranial pressure and damaging tissue.

        • Accounts for about 13% of all strokes but has a higher risk of severe outcomes.  
        • Management may include blood‐pressure control, surgical clipping or coiling of aneurysms, and evacuation of hematomas.  

        Source: American Heart Association (heart.org)  
        """
        )
,
        /*
        StrokeType(
            name: "TIA (Mini-Stroke)",
            icon: "⚠️",
            summary: "Temporary symptoms (<24 hrs)",
            details: "A Transient Ischemic Attack (TIA) is a brief blockage of blood flow in the brain that resolves within 24 hours.\n\n• Symptoms mirror stroke but are temporary.\n• TIAs are warning signs: nearly 1 in 3 people who experience a TIA will have a full stroke.\n• Immediate medical evaluation reduces future risk.\n\nSource: National Institute of Neurological Disorders and Stroke (NINDS)"
        )
         */
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Infographic-style Header
                VStack(spacing: 8) {
                    Text("Types")
                        .font(.system(size: 36, weight: .bold))
                
                    Text("Strokes come in 2 forms")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: 300)
               // .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Cards
                ForEach(types) { type in
                    NavigationLink(destination: DetailView(type: type)) {
                        CardView(icon: type.icon,
                                 title: type.name,
                                 subtitle: type.summary)
                    }
                    .padding(.horizontal)
                }
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .background(Color(.systemPink).opacity(0.1))
    }
}

// MARK: - Detail View
struct DetailView: View {
    let type: StrokeType

    var body: some View {
        VStack(spacing: 20) {
            Text(type.icon)
                .font(.system(size: 80))

            Text(type.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(type.summary)
                .font(.title3)
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                Text(type.details)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding()
            }

            Spacer()
        }
      .background(Color(.systemPink).opacity(0.1))
        
        
       // .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
    
}

// MARK: - Shared Card
struct CardView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 50))
            Text(title)
                .font(.title2)
                .foregroundStyle(.black)
                .fontWeight(.semibold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


#Preview {
    TypesView()
}
