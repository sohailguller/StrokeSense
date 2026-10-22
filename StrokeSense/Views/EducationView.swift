//
//  EducationView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//

import SwiftUI

struct EducationView: View {
    let categories = [
        EducationCategory(destination: AnyView(BefastView()), category: "B.E.F.A.S.T", imageName: "brain.head.profile"),
        EducationCategory(destination: AnyView(CausesView()), category: "Causes", imageName: "heart"),
        EducationCategory(destination: AnyView(PreventionView()), category: "Prevention", imageName: "checklist"),
        EducationCategory(destination: AnyView(TypesView()), category: "Types", imageName: "rectangle.3.group"),
        EducationCategory(destination: AnyView(TreatmentsView()), category: "Treatment", imageName: "pill")
    ]

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(categories) { category in
                        NavigationRow(destination: category.destination, category: category.category, imageName: category.imageName)
                    }
                }
            }
            Spacer()
            Text("All infographics are created by the developer(s) of this app. They contain info and recommendations based on online research. There can be mistakes. Check important info. Seek a doctor’s advice in addition to using this app and before making any medical decisions.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top)
                                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    EducationView()
}
