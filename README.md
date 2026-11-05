# StrokeSense

iOS app that helps families and bystanders spot a stroke, act fast, and understand what comes next. It's live on the [App Store](https://apps.apple.com/app/strokesense/id6743031338).

What's in it:

- B.E. F.A.S.T. walkthrough for recognizing a stroke in the moment
- Learn section on stroke types, causes, prevention and treatments
- Stroke Expert, a chat where you can ask questions in plain language
- interviews, videos and stroke news
- a small game to help the signs stick
- 20 languages

The app is SwiftUI. Stroke Expert goes through a small Cloudflare Worker in `worker/`, so no API key ever ships in the app, and requests are checked with Firebase App Check. The landing/support/privacy site is in `website/` and runs on Vercel.

This lived on my laptop for a while before I put it on GitHub.
