# BuildScout Capture browser extension

This is the user-mediated bridge for marketplaces that do not expose a buyer-side inventory API.

It has two explicit actions:

- Capture this listing: captures the current page's canonical URL, title, metadata, JSON-LD and visible text.
- Capture visible result cards: captures only listing links already rendered in the current page, up to 60 leads.

The extension does not paginate, crawl in the background, transmit cookies, or send captured content to a BuildScout server. It sends the capture directly to the locally installed macOS app using the buildscout:// URL scheme. The current listing is also copied to the clipboard as a fallback.

## Firefox

1. Open about:debugging#/runtime/this-firefox.
2. Choose Load Temporary Add-on.
3. Select browser-extension/manifest.json.
4. Open a Marketplace/Kijiji/Craigslist/etc. page.
5. Click the BuildScout Capture toolbar icon.

For permanent public Firefox distribution, package/sign the WebExtension through Mozilla Add-ons.

## Chrome / Chromium / Edge / Brave

1. Open the browser's Extensions page.
2. Enable developer mode.
3. Choose Load unpacked.
4. Select the browser-extension directory.
5. Click the toolbar icon while viewing a listing or search page.

## Why this bridge exists

Some marketplaces contain enormous amounts of project-car inventory but do not provide a general public buyer-side search API. BuildScout therefore supports several independent routes:

1. official APIs and feeds when available;
2. opt-in third-party provider APIs;
3. indexed discovery;
4. explicit user-mediated browser capture;
5. JSON / CSV exports.

The capture extension is the highest-fidelity fallback because it operates on the page the user is already authorized to view.
