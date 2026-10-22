//
//  TreatmentsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 6/30/25.
//
import SwiftUI

// MARK: - Treatments Data Model
struct Treatment: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let summary: String
    let details: String
}

// MARK: - Treatments View with Details
struct TreatmentsView: View {
    let treatments: [Treatment] = [
            Treatment(
                name: "Clot‑busting Medication",
                icon: "💊",
                summary: "tPA to dissolve clots",
                details: "A tissue plasminogen activator (tPA) is a special medicine given through an IV to help dissolve blood clots in the brain.\n\n• Best when started within 3–4.5 hours of symptom onset.\n• Can improve recovery and reduce disability.\n• Not used if there is bleeding risk (recent surgery, bleeding disorders).\n\nSource: American Heart Association (heart.org)"
            ),
            Treatment(
                name: "Mechanical Thrombectomy",
                icon: "🛠️",
                summary: "Catheter-based clot removal",
                details: "A thin tube (catheter) is guided through an artery to the brain to physically remove the clot.\n\n• Most effective when started within 6–24 hours, depending on patient condition.\n• Often used along with tPA for larger vessel strokes.\n• Can restore blood flow quickly, reducing brain damage.\n\nSource: American Heart Association (heart.org)"
            ),
            Treatment(
                name: "Hemorrhage Surgery",
                icon: "🪡",
                summary: "Treat bleeding in brain",
                details: "In hemorrhagic stroke, surgery may be needed to stop bleeding and relieve pressure.\n\n• Options include clipping or coiling an aneurysm to seal a bleeding vessel.\n• A craniotomy can remove pooled blood (hematoma) and lower pressure.\n• Quick treatment can prevent further brain injury.\n\nSource: American Heart Association (heart.org)"
            )
        ]


    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Infographic-style Header
                VStack(spacing: 8) {
                    Text("Treatments")
                        .font(.system(size: 36, weight: .bold))
                    Text("Key interventions to manage stroke")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
              //  .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Treatment cards
                ForEach(treatments) { t in
                    NavigationLink(destination: TreatmentDetailView(treatment: t)) {
                        CardView(icon: t.icon, title: t.name, subtitle: t.summary)
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

struct TreatmentDetailView: View {
    let treatment: Treatment
    var body: some View {
        VStack(spacing: 20) {
            Text(treatment.icon)
                .font(.system(size: 80))
            Text(treatment.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text(treatment.summary)
                .font(.title3)
                .foregroundColor(.secondary)
            Divider()
            ScrollView {
                Text(treatment.details)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .background(Color(.systemPink).opacity(0.1))

        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TreatmentsView()
    }
}
