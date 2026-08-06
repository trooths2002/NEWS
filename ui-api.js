import express from "express";
import fs from "fs";
import path from "path";
import cors from "cors";

const app = express();
app.use(cors());

const ROOT = process.cwd();
const UI_DIR = path.join(ROOT, "ui");

// Serve the static UI at /ui and redirect / -&gt; /ui
app.use("/ui", express.static(UI_DIR));
app.get("/", (req, res) =&gt; res.redirect("/ui"));

function readJson(rel) {
  try {
    const p = path.join(ROOT, rel);
    if (!fs.existsSync(p)) return null;
    return JSON.parse(fs.readFileSync(p, "utf-8"));
  } catch {
    return null;
  }
}

// GET /api/news?region=&amp;topic=&amp;q=
app.get("/api/news", (req, res) =&gt; {
  const data = readJson("news-intelligence.json") || { items: [] };
  const { region, topic, q } = req.query;

  let items = Array.isArray(data.items) ? data.items : [];
  if (region) items = items.filter(i =&gt; (i.region || "").toLowerCase() === String(region).toLowerCase());
  if (topic)  items = items.filter(i =&gt; (i.topic  || "").toLowerCase().includes(String(topic).toLowerCase()));
  if (q) {
    const needle = String(q).toLowerCase();
    items = items.filter(i =&gt;
      [i.title, i.summary, i.source, i.url]
        .filter(Boolean)
        .some(v =&gt; String(v).toLowerCase().includes(needle))
    );
  }
  res.json({ count: items.length, items });
});

// GET /api/briefs
app.get("/api/briefs", (req, res) =&gt; {
  const rpt = readJson("diagnostic-results.json") || readJson("report.json") || {};
  res.json(rpt);
});

// GET /api/health
app.get("/api/health", async (req, res) =&gt; {
  const cfg = readJson("production-config.json") || readJson("mcp.config.json") || {};
  res.json({
    ok: true,
    services: Object.keys(cfg).length ? Object.keys(cfg) : ["mcp-orchestrator","collector","reporter"],
    timestamp: new Date().toISOString()
  });
});

const port = process.env.PORT || 4000;
app.listen(port, () =&gt; console.log(`UI API running on http://localhost:${port} (UI at /ui)`));