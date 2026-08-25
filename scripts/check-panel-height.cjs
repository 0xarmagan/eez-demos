#!/usr/bin/env node
/* Assert no walkthrough's code panel clips at any step.
 *
 * The panel is fixed-height with overflow-y:hidden: 16 lines fit, 17 clip,
 * and the ~11px overflow is invisible in a screenshot. audit.sh cannot see
 * this — it has passed on a file that was actively clipping.
 *
 * Usage: node scripts/check-panel-height.cjs [file.html ...]
 *        (no args = every tracked walkthrough)
 *
 * Needs puppeteer. This repo has no node_modules, so if `require` cannot
 * find it, point NODE_PATH at a directory that has it, e.g. one of npx's
 * caches under ~/.npm/_npx:
 *   NODE_PATH=/path/to/node_modules node scripts/check-panel-height.cjs
 */
const { execSync } = require("child_process");
const path = require("path");

let puppeteer;
try {
  puppeteer = require("puppeteer");
} catch (e) {
  console.error("puppeteer not resolvable. Install it, or set NODE_PATH to a");
  console.error("node_modules directory that already has it (see the header).");
  process.exit(2);
}

async function main() {
  let files = process.argv.slice(2);
  if (files.length === 0) {
    files = execSync("git ls-files '*/q*.html' '*/ro*.html' '*/pr*.html'", {
      encoding: "utf8",
      cwd: path.resolve(__dirname, ".."),
    })
      .split("\n")
      .filter(Boolean)
      .map((f) => path.resolve(__dirname, "..", f));
  }

  const browser = await puppeteer.launch({ args: ["--no-sandbox"] });
  let failures = 0;
  let checked = 0;

  for (const f of files) {
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });
    const target = "file://" + path.resolve(f);
    await page.goto(target, { waitUntil: "load" });

    // A redirect stub (meta refresh at a moved page's old path) lands on the
    // real page, which would then be measured twice under two names.
    await new Promise((r) => setTimeout(r, 150));
    if (page.url() !== target) {
      await page.close();
      continue;
    }

    // eez-tour.js auto-runs on a first visit, and its overlay sits on top of
    // #btnNext. A fresh browser profile is always a first visit, so without
    // this the Next clicks land on the tour and every step measures step 1 —
    // the checker passes while testing nothing. Dismiss it first.
    await new Promise((r) => setTimeout(r, 150));
    const skip = await page.$("#tourSkip");
    if (skip) {
      await skip.click();
      await new Promise((r) => setTimeout(r, 150));
    }

    // A page with no step dots is not a walkthrough (e.g. a redirect stub).
    const steps = await page.$$eval("#dots > div", (d) => d.length).catch(() => 0);
    if (!steps) {
      await page.close();
      continue;
    }
    checked++;
    for (let i = 0; i < steps; i++) {
      if (i > 0) await page.click("#btnNext");
      await new Promise((r) => setTimeout(r, 120));
      // Prove the click actually advanced the deck before trusting the
      // measurement, so a swallowed click fails loudly instead of silently
      // re-measuring the same step.
      const label = await page.$eval("#stepLabel", (el) => el.textContent.trim());
      const want = String(i + 1).padStart(2, "0") + " / " + String(steps).padStart(2, "0");
      if (label !== want) {
        console.error(`STUCK ${f}  expected step label ${want}, got ${label}`);
        failures++;
        break;
      }
      const m = await page.$eval("#codePanel", (el) => ({
        scroll: el.scrollHeight,
        client: el.clientHeight,
      }));
      if (m.scroll > m.client) {
        console.error(
          `CLIP  ${f}  step ${i + 1}/${steps}  ${m.scroll} > ${m.client}`
        );
        failures++;
      }
    }
    await page.close();
  }

  await browser.close();
  console.log(
    failures === 0
      ? `No clipping across ${checked} file(s).`
      : `${failures} clipping state(s).`
  );
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
