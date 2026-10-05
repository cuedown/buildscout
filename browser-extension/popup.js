const api = globalThis.browser ?? globalThis.chrome;

const statusEl = document.getElementById("status");
document.getElementById("listing").addEventListener("click", () => capture("listing"));
document.getElementById("visible").addEventListener("click", () => capture("visible"));

async function capture(mode) {
  try {
    statusEl.textContent = "Reading the current tab…";
    const tabs = await api.tabs.query({ active: true, currentWindow: true });
    const tab = tabs[0];
    if (!tab || !tab.id) throw new Error("No active tab.");

    const execution = await api.scripting.executeScript({
      target: { tabId: tab.id },
      func: collectPage,
      args: [mode]
    });

    const payload = execution && execution[0] && execution[0].result;
    if (!payload) throw new Error("The page did not return a capture.");

    const clipboardText = [payload.title, payload.text, payload.url].filter(Boolean).join("\n");
    await navigator.clipboard.writeText(clipboardText);

    const encoded = base64url(JSON.stringify(payload));
    const deepLink = "buildscout://capture?data=" + encoded;

    statusEl.textContent = mode === "visible"
      ? "Captured " + ((payload.items && payload.items.length) || 0) + " visible leads. Opening BuildScout…"
      : "Captured listing. Opening BuildScout…";

    const a = document.createElement("a");
    a.href = deepLink;
    a.style.display = "none";
    document.body.appendChild(a);
    a.click();
    a.remove();

    setTimeout(() => {
      statusEl.textContent += " If it did not open, the listing text is already on your clipboard.";
    }, 1200);
  } catch (error) {
    statusEl.textContent = "Capture failed: " + (error && error.message ? error.message : error);
  }
}

function collectPage(mode) {
  const canonicalNode = document.querySelector('link[rel="canonical"]');
  const canonical = (canonicalNode && canonicalNode.href) || location.href;
  const ogTitleNode = document.querySelector('meta[property="og:title"]');
  const ogDescriptionNode = document.querySelector('meta[property="og:description"]');
  const metaDescriptionNode = document.querySelector('meta[name="description"]');
  const ogTitle = (ogTitleNode && ogTitleNode.content) || "";
  const ogDescription = (ogDescriptionNode && ogDescriptionNode.content) || "";
  const metaDescription = (metaDescriptionNode && metaDescriptionNode.content) || "";
  const selection = (window.getSelection && window.getSelection().toString().trim()) || "";

  const jsonLd = Array.from(document.querySelectorAll('script[type="application/ld+json"]'))
    .map(node => (node.textContent || "").trim())
    .filter(Boolean)
    .join("\n")
    .slice(0, 12000);

  const visibleBody = (document.body && document.body.innerText ? document.body.innerText : "").slice(0, 18000);
  const title = ogTitle || document.title || canonical;
  const text = uniqueChunks([selection, ogDescription, metaDescription, jsonLd, visibleBody])
    .join("\n")
    .slice(0, 22000);

  return {
    url: canonical,
    title,
    text,
    items: mode === "visible" ? visibleListingCards() : []
  };
}

function visibleListingCards() {
  const patterns = [
    /facebook\.[^/]+\/marketplace\/item\//i,
    /kijiji\.[^/]+\/v-cars-trucks\//i,
    /craigslist\.[^/]+\/(?:cto|ctd|pts)\//i,
    /autotrader\.[^/]+\/a\//i,
    /copart\.[^/]+\/lot\//i,
    /iaai\.[^/]+\/vehicledetail\//i,
    /ebay\.[^/]+\/itm\//i
  ];

  const seen = new Set();
  const output = [];

  for (const anchor of document.querySelectorAll("a[href]")) {
    if (output.length >= 60) break;

    let href;
    try {
      href = new URL(anchor.href, location.href).href;
    } catch {
      continue;
    }

    if (!patterns.some(pattern => pattern.test(href))) continue;

    href = href.split("#")[0];
    if (seen.has(href)) continue;

    const container = usefulContainer(anchor);
    const text = ((container && container.innerText) || anchor.innerText || "")
      .replace(/\n{3,}/g, "\n\n")
      .trim()
      .slice(0, 2400);

    if (text.length < 8) continue;
    seen.add(href);

    output.push({
      url: href,
      title: (anchor.getAttribute("aria-label") || anchor.innerText || text.split("\n")[0] || "").trim().slice(0, 220),
      text
    });
  }

  return output;
}

function usefulContainer(anchor) {
  let node = anchor;
  let best = anchor;

  for (let i = 0; i < 7 && node; i += 1, node = node.parentElement) {
    const text = (node.innerText || "").trim();
    if (text.length >= 30 && text.length <= 2600) {
      best = node;
      if (node.matches && node.matches("article, li, [role='article'], [data-testid*='listing'], [class*='listing'], [class*='card']")) break;
    }
  }

  return best;
}

function uniqueChunks(chunks) {
  const seen = new Set();
  return chunks.filter(chunk => {
    if (!chunk) return false;
    const normalized = chunk.trim();
    if (!normalized || seen.has(normalized)) return false;
    seen.add(normalized);
    return true;
  });
}

function base64url(text) {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}
