// StrokeSense privacy policy, served at /privacy. Linked from the app's Profile screen and
// used as the Privacy Policy URL in App Store Connect (App Store Review Guideline 5.1.1).

const POLICY = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>StrokeSense Privacy Policy</title>
<style>
  :root { color-scheme: light dark; --ink: #1F2328; --muted: #6B6F76; --bg: #FAF8F6; --accent: #D1102E; }
  @media (prefers-color-scheme: dark) { :root { --ink: #F2EFEC; --muted: #A0A4AB; --bg: #0B0A0A; --accent: #FF375F; } }
  body { margin: 0; background: var(--bg); color: var(--ink);
         font: 17px/1.55 ui-rounded, -apple-system, system-ui, sans-serif; }
  main { max-width: 680px; margin: 0 auto; padding: 24px 20px 48px; }
  h1 { font-size: 30px; line-height: 1.2; margin: 8px 0 4px; }
  h2 { font-size: 20px; margin: 28px 0 6px; }
  p, li { margin: 6px 0; }
  .updated { color: var(--muted); margin-bottom: 20px; }
  a { color: var(--accent); }
</style>
</head>
<body>
<main>
<h1>StrokeSense Privacy Policy</h1>
<p class="updated">Last updated October 22, 2026</p>

<p>StrokeSense teaches people about stroke. It has no accounts, no ads and no tracking. This policy explains what data the app handles and where it goes.</p>

<h2>Data that stays on your iPhone</h2>
<ul>
  <li>Your name and profile photo, if you add them.</li>
  <li>Podcast episodes you save, your appearance setting and your Stroke Expert sharing choice.</li>
</ul>
<p>This data is never uploaded. Deleting the app deletes it.</p>

<h2>Questions you ask the Stroke Expert</h2>
<p>When you type your own question and agree to share it, the question and the rest of that conversation are sent through the StrokeSense server to OpenAI, which writes the answer. StrokeSense does not store your questions. OpenAI may use them to improve its models. Don't include your name or personal health details. The suggested questions are answered on your iPhone and are never sent.</p>
<p>You can stop sharing at any time in Profile by turning off Share Questions with OpenAI. See <a href="https://openai.com/policies/privacy-policy">OpenAI's privacy policy</a>.</p>

<h2>Services the app uses</h2>
<ul>
  <li><strong>Firebase (Google)</strong> loads the list of podcast episodes and verifies that requests come from the real app (App Check). It may process technical data such as your IP address and device information.</li>
  <li><strong>YouTube (Google)</strong> plays podcast episodes when you open one.</li>
  <li><strong>Cloudflare</strong> runs the StrokeSense server that forwards Stroke Expert questions and gathers stroke news.</li>
  <li>Articles you open load from their publishers' websites.</li>
</ul>

<h2>Children</h2>
<p>StrokeSense is not directed at children under 13 and does not knowingly collect their personal information.</p>

<h2>Not medical advice</h2>
<p>StrokeSense provides general education, not medical advice. If you notice signs of a stroke, call 911 or your local emergency number right away.</p>

<h2>Changes</h2>
<p>If this policy changes, the date above will be updated.</p>
</main>
</body>
</html>`;

export function handlePrivacy() {
  return new Response(POLICY, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=3600",
    },
  });
}
