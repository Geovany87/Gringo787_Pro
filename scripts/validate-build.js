// scripts/validate-build.js
import fs from "fs";
import path from "path";
import { JSDOM } from "jsdom";

const distDir = path.resolve("dist");
if (!fs.existsSync(distDir)) {
  console.error("❌ dist/ folder not found — build step didn’t run.");
  process.exit(1);
}

const htmlFiles = fs
  .readdirSync(distDir, { withFileTypes: true })
  .filter(f => f.isFile() && f.name.endsWith(".html"))
  .map(f => path.join(distDir, f.name));

let missingAssets = [];

for (const file of htmlFiles) {
  const html = fs.readFileSync(file, "utf-8");
  const dom = new JSDOM(html);
  const links = [
    ...Array.from(dom.window.document.querySelectorAll("link[rel='stylesheet']"))
      .map(el => el.getAttribute("href")),
    ...Array.from(dom.window.document.querySelectorAll("script[src]"))
      .map(el => el.getAttribute("src")),
  ];

  for (const link of links) {
    if (!link) continue;
    const cleanLink = link.split("?")[0]; // strip query params
    const assetPath = path.join(distDir, cleanLink.replace(/^\//, ""));
    if (!fs.existsSync(assetPath)) {
      missingAssets.push({ html: path.basename(file), asset: link });
    }
  }
}

if (missingAssets.length) {
  console.error("❌ Missing build assets detected:");
  missingAssets.forEach(m =>
    console.error(`- ${m.asset} referenced in ${m.html} but not found`)
  );
  process.exit(1);
}

console.log("✅ All referenced CSS/JS assets exist in dist.");
