const API = window.UI_API_URL || "http://localhost:4000";

const qs = s =&gt; document.querySelector(s);
const tabFeed   = qs("#tab-feed");
const tabBriefs = qs("#tab-briefs");
const tabHealth = qs("#tab-health");

const filters   = qs("#filters");
const countEl   = qs("#count");
const gridEl    = qs("#grid");
const briefsEl  = qs("#briefs");
const healthEl  = qs("#health");
const qEl = qs("#q"), regionEl = qs("#region"), topicEl = qs("#topic");
const btnFilter = qs("#btnFilter");

let active = "feed";

function setTab(tab) {
  active = tab;
  for (const [btn, name] of [[tabFeed,"feed"],[tabBriefs,"briefs"],[tabHealth,"health"]]) {
    btn.className = "px-4 py-2 rounded-xl border " + (active===name ? "bg-black text-white" : "bg-white");
  }
  filters.classList.toggle("hidden", active !== "feed");
  gridEl.classList.toggle("hidden", active !== "feed");
  countEl.classList.toggle("hidden", active !== "feed");
  briefsEl.classList.toggle("hidden", active !== "briefs");
  healthEl.classList.toggle("hidden", active !== "health");
}

async function fetchJSON(url) {
  const r = await fetch(url);
  return r.json();
}

async function loadFeed() {
  const params = new URLSearchParams({
    q: qEl.value || "",
    region: regionEl.value || "",
    topic: topicEl.value || ""
  }).toString();
  const data = await fetchJSON(`${API}/api/news?${params}`);
  countEl.textContent = `Results: ${data.count}`;
  gridEl.innerHTML = (data.items || []).map((n) =&gt; `
    &lt;a href="${n.url || '#'}" target="_blank" class="block border rounded-2xl p-4 bg-white hover:shadow"&gt;
      &lt;div class="text-xs text-gray-500 mb-1"&gt;${[n.source,n.region,n.topic].filter(Boolean).join(" • ")}&lt;/div&gt;
      &lt;div class="font-semibold mb-1"&gt;${n.title || "Untitled"}&lt;/div&gt;
      &lt;div class="text-sm text-gray-700"&gt;${(n.summary || "").slice(0,240)}&lt;/div&gt;
      &lt;div class="text-xs mt-2 text-gray-500"&gt;${n.publishedAt || ""}&lt;/div&gt;
    &lt;/a&gt;
  `).join("");
}

async function loadBriefs() {
  const b = await fetchJSON(`${API}/api/briefs`);
  briefsEl.textContent = JSON.stringify(b, null, 2);
}

async function loadHealth() {
  const h = await fetchJSON(`${API}/api/health`);
  healthEl.innerHTML = `
    &lt;div class="border rounded-2xl p-4 bg-white"&gt;
      &lt;div class="text-sm text-gray-500"&gt;Status&lt;/div&gt;
      &lt;div class="text-xl font-semibold"&gt;${h.ok ? "Healthy" : "Degraded"}&lt;/div&gt;
    &lt;/div&gt;
    &lt;div class="border rounded-2xl p-4 bg-white"&gt;
      &lt;div class="text-sm text-gray-500"&gt;Services&lt;/div&gt;
      &lt;div class="text-sm"&gt;${(h.services||[]).join(", ")}&lt;/div&gt;
    &lt;/div&gt;
    &lt;div class="border rounded-2xl p-4 bg-white"&gt;
      &lt;div class="text-sm text-gray-500"&gt;Updated&lt;/div&gt;
      &lt;div class="text-sm"&gt;${h.timestamp || ""}&lt;/div&gt;
    &lt;/div&gt;
  `;
}

tabFeed.addEventListener("click",  () =&gt; { setTab("feed");   loadFeed();  });
tabBriefs.addEventListener("click",() =&gt; { setTab("briefs"); loadBriefs();});
tabHealth.addEventListener("click",() =&gt; { setTab("health"); loadHealth();});
btnFilter.addEventListener("click", loadFeed);

setTab("feed");
loadFeed();