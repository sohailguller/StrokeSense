//
//  ChatView.swift
//  AIChatBot
//
//  Created by Sohail Guller on 2/21/25.
//
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    // The system prompt lives in the chat Worker (worker/src/index.js).
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    let openAIClient = OpenAIClient()

    let frequentlyAsked: [String: String] = [
        "What is a stroke?": """
        A **stroke** is a medical emergency that happens when blood flow to a part of the brain is blocked or when a blood vessel in the brain bursts. This causes brain cells to stop receiving oxygen and nutrients, leading to damage or death of those cells.

        There are two main types of stroke:
        1. **Ischemic stroke** – Caused by a blockage (such as a blood clot) in an artery supplying blood to the brain.
        2. **Hemorrhagic stroke** – Caused by a blood vessel in the brain bursting, leading to bleeding in or around the brain.

        A **Transient Ischemic Attack (TIA)**, or "mini-stroke," is a temporary blockage that resolves on its own but is a warning sign for a possible future stroke.

        Common **symptoms** include sudden weakness or numbness (especially on one side of the body), trouble speaking, vision problems, dizziness, and severe headache. Acting **FAST** (Face drooping, Arm weakness, Speech difficulty, Time to call emergency services) can save lives.
        """,
        "What are the symptoms of a stroke?": """
        The symptoms of a **stroke** appear suddenly and may include:

        1. **Numbness or weakness** in the face, arm, or leg, especially on one side of the body.
        2. **Confusion** or trouble speaking and understanding speech.
        3. **Vision problems** in one or both eyes.
        4. **Dizziness, trouble walking, or loss of balance and coordination.**
        5. **Severe headache** with no known cause.

        A simple way to remember stroke symptoms is **FAST**:
        - **F**ace drooping – One side of the face may droop or feel numb.
        - **A**rm weakness – One arm may feel weak or drift downward.
        - **S**peech difficulty – Speech may be slurred or hard to understand.
        - **T**ime to call emergency services – Immediate medical attention is needed.

        If you notice any of these symptoms, seek emergency help right away!
        """,
        "How can I prevent a stroke?": """
        You can reduce your risk of stroke by making healthy lifestyle choices and managing medical conditions. Here are key steps to prevent stroke:

        1. **Control Blood Pressure** – High blood pressure is a major stroke risk. Keep your numbers in a healthy range.
        2. **Manage Diabetes** – Keep blood sugar levels under control.
        3. **Quit Smoking** – Smoking damages blood vessels and increases clot formation.
        4. **Exercise Regularly** – Aim for at least 30 minutes of moderate activity most days of the week.
        5. **Eat a Healthy Diet** – Choose more fruits, vegetables, whole grains, and lean proteins. Limit salt, unhealthy fats, and processed foods.
        6. **Maintain a Healthy Weight** – Obesity increases stroke risk. Losing excess weight helps lower blood pressure and diabetes risk.
        7. **Limit Alcohol** – Drinking too much alcohol can raise blood pressure and increase stroke risk.
        8. **Control Cholesterol** – High cholesterol can lead to clogged arteries. Choose heart-healthy foods and medications if needed.
        9. **Treat Atrial Fibrillation (AFib)** – This irregular heart rhythm can cause blood clots that lead to stroke. Get treatment if diagnosed.
        10. **Manage Stress** – Chronic stress can contribute to high blood pressure and unhealthy habits.

        If you have a high risk of stroke, your doctor may recommend medications like blood thinners or cholesterol-lowering drugs. Regular check-ups can help identify and manage risk factors early.
        """
    ]

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(messages.filter { $0.role != "system" }) { message in
                                ChatRow(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.top)
                    }
                    .onChange(of: messages.count) { _,_ in
                        if let lastMessage = messages.last {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .padding()
                }

                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        ForEach(frequentlyAsked.keys.sorted(), id: \.self) { question in
                            Button(action: {
                                let response = frequentlyAsked[question] ?? ""
                                let userMessage = ChatMessage(role: "user", content: question)
                                let assistantMessage = ChatMessage(role: "assistant", content: response)
                                messages.append(userMessage)
                                messages.append(assistantMessage)
                            }) {
                                Text(question)
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                HStack {
                    TextField("Ask your question...", text: $inputText)
                        .padding(12)
                        .background(Color(white: 0.95))
                        .cornerRadius(20)
                        .padding(.leading, 16)

                    Button(action: {
                        sendMessage()
                    }) {
                        Text("Send")
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 8)
                .background(Color(white: 0.98))
                Text("Responses are AI generated. They are not a substitute for professional medical advice. Consult with qualified healthcare providers for medical decisions. Questions are processed by OpenAI and may be used to improve their models, so avoid sharing personal details.")
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .padding(.horizontal)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("AI Stroke Expert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    NavigationLink {
                        NavigationTabView(saveAction: {})
                            .environmentObject(store)
                            .environmentObject(favoritesManager)
                            .navigationBarBackButtonHidden()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                            .padding()
                    }
                }
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Stroke Expert Unavailable"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""

        let chatHistory = messages
            .filter { $0.role == "user" || $0.role == "assistant" }
            .map { Message(role: $0.role, content: $0.content) }

        isLoading = true

        Task {
            do {
                let response = try await openAIClient.sendMessage(messages: chatHistory)
                let chatResponse = ChatMessage(role: response.role, content: response.content)
                await MainActor.run {
                    messages.append(chatResponse)
                    isLoading = false
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(UserStore())
        .environmentObject(FavoritesManager())
}
