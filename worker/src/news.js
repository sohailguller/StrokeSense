// Recent stroke news for the app's News section, built from credible research-news RSS feeds.
// Cached at the edge so the feeds are fetched at most every few hours, not on every app launch.

const FEEDS = [
  { source: "ScienceDaily", url: "https://www.sciencedaily.com/rss/mind_brain/stroke.xml" },
  { source: "Medical Xpress", url: "https://medicalxpress.com/rss-feed/search/?search=stroke" },
];

const CACHE_SECONDS = 6 * 60 * 60;
const MAX_AGE_DAYS = 60;
const MAX_ARTICLES = 12;
const USER_AGENT = "Mozilla/5.0 (compatible; StrokeSense/2.0; +https://strokesense-chat.ims03g.workers.dev)";

// "stroke" the condition, not "heat stroke", "sunstroke" or "brushstroke".
const STROKE = /\bstrokes?\b/i;
const NOT_STROKE = /\b(heat|sun|brush|pen|master|key|swim(ming)?|golf)[ -]?strokes?\b/i;

export async function handleNews(request, ctx) {
  const cache = caches.default;
  const cacheKey = new Request(new URL("/news", request.url).toString());
  const cached = await cache.match(cacheKey);
  if (cached) return cached;

  const results = await Promise.allSettled(FEEDS.map(loadFeed));
  const seen = new Set();
  const cutoff = Date.now() - MAX_AGE_DAYS * 24 * 60 * 60 * 1000;

  const articles = results
    .flatMap((result) => (result.status === "fulfilled" ? result.value : []))
    .filter((a) => a.publishedAt >= cutoff)
    .filter((a) => STROKE.test(`${a.title} ${a.description}`) && !NOT_STROKE.test(a.title))
    .filter((a) => {
      const key = a.title.toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .sort((a, b) => b.publishedAt - a.publishedAt)
    .slice(0, MAX_ARTICLES);

  await Promise.all(
    articles.map(async (a) => {
      if (!a.imageURL) a.imageURL = await findPreviewImage(a.url);
    })
  );

  const body = {
    articles: articles.map((a) => ({
      title: a.title,
      url: a.url,
      source: a.source,
      description: a.description,
      imageURL: a.imageURL || "",
      publishedAt: new Date(a.publishedAt).toISOString(),
    })),
  };

  const response = Response.json(body, {
    headers: { "Cache-Control": `public, max-age=${CACHE_SECONDS}` },
  });
  // Only cache a useful answer, so a temporary feed outage doesn't stick for hours.
  if (articles.length > 0) ctx.waitUntil(cache.put(cacheKey, response.clone()));
  return response;
}

async function loadFeed(feed) {
  const response = await fetch(feed.url, { headers: { "User-Agent": USER_AGENT } });
  if (!response.ok) throw new Error(`${feed.source} feed returned ${response.status}`);
  const xml = await response.text();

  return [...xml.matchAll(/<item\b[\s\S]*?<\/item>/g)].map(([item]) => ({
    source: feed.source,
    title: decode(tag(item, "title")),
    url: decode(tag(item, "link")).trim(),
    description: truncate(stripHTML(decode(tag(item, "description"))), 160),
    publishedAt: Date.parse(tag(item, "pubDate")) || 0,
    imageURL: attribute(item, "media:thumbnail", "url") || attribute(item, "media:content", "url") || "",
  })).filter((a) => a.title && a.url.startsWith("https://"));
}

// The article page's og:image, or "" if it can't be found quickly.
async function findPreviewImage(url) {
  let image = "";
  try {
    const response = await fetch(url, {
      headers: { "User-Agent": USER_AGENT },
      signal: AbortSignal.timeout(4000),
    });
    if (!response.ok) return "";
    await new HTMLRewriter()
      .on('meta[property="og:image"]', {
        element(el) {
          if (!image) image = el.getAttribute("content") || "";
        },
      })
      .transform(response)
      .arrayBuffer();
  } catch {
    return "";
  }
  return image.startsWith("https://") ? image : "";
}

function tag(xml, name) {
  const match = xml.match(new RegExp(`<${name}\\b[^>]*>([\\s\\S]*?)</${name}>`));
  if (!match) return "";
  return match[1].replace(/^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/, "$1").trim();
}

function attribute(xml, name, attr) {
  const match = xml.match(new RegExp(`<${name}\\b[^>]*\\b${attr}="([^"]+)"`));
  return match ? decode(match[1]) : "";
}

function decode(text) {
  return text
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCodePoint(parseInt(code, 16)))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&");
}

function stripHTML(text) {
  return text.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
}

function truncate(text, length) {
  return text.length > length ? `${text.slice(0, length - 1).trimEnd()}…` : text;
}
