#!/usr/bin/env node
/* CI-only browser checks. Every HTTP request is intercepted: fixtures come
 * from tracked files, fonts are stubbed, and no live RPC or wallet is used.
 * Displayed shell commands are inspected as text, never executed. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { createHash } = require("node:crypto");
const { execFileSync } = require("node:child_process");
const puppeteer = require("puppeteer");

const root = path.resolve(__dirname, "..");
const base = "http://127.0.0.1:8765/review/";
const skillPath = "skills/eez-dapp-quickstart/SKILL.md";
const skill = fs.readFileSync(path.join(root, skillPath));
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");
const tracked = new Set(execFileSync("git", ["ls-files", "-z"], { cwd: root, encoding: "utf8" }).split("\0").filter(Boolean));
const digest = /var SKILL_SHA256 = "([a-f0-9]{64})"/.exec(read("assets/eez-skill.js"));
assert.ok(digest, "The skill must have a reviewed SHA-256 digest");
assert.equal(createHash("sha256").update(skill).digest("hex"), digest[1], "Review SKILL.md before updating its digest");
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const payload = '<img src=x onerror="window.injected=true">';

async function open(browser, file, options = {}) {
  const page = await browser.newPage();
  const state = { unexpected: [], errors: [], skillRequests: 0 };
  await page.setViewport({ width: options.width || 1280, height: 900 });
  await page.setRequestInterception(true);
  page.on("request", async (request) => {
    try {
      const url = new URL(request.url());
      if (url.protocol === "data:" || url.protocol === "blob:") { await request.continue(); return; }
      if (url.origin === new URL(base).origin && url.pathname.startsWith("/review/")) {
        const rel = decodeURIComponent(url.pathname.slice("/review/".length));
        if (request.method() !== "GET" || !tracked.has(rel)) {
          state.unexpected.push(request.method() + " " + request.url());
          await request.abort(); return;
        }
        if (rel === skillPath) {
          state.skillRequests++;
          if (options.skillDelay) { await delay(options.skillDelay); }
          if (options.skillMode === "redirect") {
            await request.respond({ status: 302, headers: { location: "https://example.invalid/replacement.md" } });
            return;
          }
          const body = options.skillMode === "tampered" ? Buffer.concat([skill, Buffer.from("\nChanged instructions")])
            : options.skillMode === "html" ? Buffer.from("<!doctype html><h1>Unavailable</h1>") : skill;
          await request.respond({ status: options.skillMode === "missing" ? 404 : 200, contentType: "text/plain; charset=utf-8", body });
          return;
        }
        const type = { ".html": "text/html", ".js": "text/javascript", ".svg": "image/svg+xml", ".png": "image/png", ".md": "text/plain" }[path.extname(rel)];
        if (!type) { state.unexpected.push(request.url()); await request.abort(); return; }
        await request.respond({ status: 200, contentType: type, body: fs.readFileSync(path.join(root, rel)) });
      } else if (url.origin === "https://fonts.googleapis.com" && request.resourceType() === "stylesheet") {
        await request.respond({ status: 200, contentType: "text/css", body: "" });
      } else {
        state.unexpected.push(request.url());
        await request.abort();
      }
    } catch (error) {
      state.errors.push(String(error));
      if (!request.isInterceptResolutionHandled()) { await request.abort(); }
    }
  });
  page.on("pageerror", (error) => state.errors.push(String(error)));
  await page.evaluateOnNewDocument((clipboardMissing) => {
    window.copied = [];
    window.walletAccesses = 0;
    window.injected = false;
    Object.defineProperty(window, "ethereum", { get() { window.walletAccesses++; return undefined; } });
    Object.defineProperty(navigator, "clipboard", { configurable: true, value: clipboardMissing ? undefined : {
      writeText: async (text) => { if (window.rejectCopy) { throw new Error("Denied"); } window.copied.push(text); },
    } });
  }, !!options.clipboardMissing);
  await page.goto(base + file + (options.hostileURL ? "?q=" + encodeURIComponent(payload) + "#step-" + encodeURIComponent(payload) : ""), { waitUntil: "load" });
  return { page, state };
}

async function clean(page, state) {
  assert.deepEqual(state.unexpected, [], "Unexpected network request");
  assert.deepEqual(state.errors, [], "Browser error");
  assert.equal(await page.evaluate(() => window.walletAccesses), 0, "Browsing must not access a wallet");
  assert.equal(await page.evaluate(() => window.injected), false, "Input was executed as HTML");
  await page.close();
}

async function browsing(browser) {
  const pages = [...tracked].filter((file) => file.endsWith(".html") && !file.startsWith("docs/"));
  for (const file of pages) {
    const { page, state } = await open(browser, file, { hostileURL: true });
    await page.evaluate((text) => {
      document.querySelectorAll('input[type="text"], input:not([type]), textarea').forEach((input) => {
        input.value = text;
        input.dispatchEvent(new Event("input", { bubbles: true }));
      });
    }, payload);
    const start = await page.$("#btnStart");
    if (start) {
      await start.click();
      await page.evaluate(() => document.querySelectorAll("#dots button").forEach((button) => button.click()));
    }
    await delay(50);
    assert.equal(state.skillRequests, 0, "Skill must not fetch until requested");
    assert.deepEqual(await page.evaluate(() => window.copied), [], "Browsing must not write the clipboard");
    await clean(page, state);
  }
  console.log(`Browsing boundaries pass for ${pages.length} pages, including hostile URL/search/calculator inputs.`);
}

async function agentSkill(browser) {
  const file = "dapp-developers/qs1-run-your-first-round-trip.html";
  for (const width of [1280, 390]) {
    const { page, state } = await open(browser, file, { width, skillDelay: 150 });
    await page.click(".skill-open");
    assert.equal(await page.$eval('[data-copy="file"]', (button) => button.disabled), true);
    await page.waitForFunction(() => !document.querySelector('[data-copy="file"]').disabled);
    // The browser checks bytes before making the reviewed text available.
    await page.click('[data-copy="file"]');
    await page.waitForFunction(() => window.copied.length === 1);
    assert.equal(await page.evaluate(() => window.copied[0]), skill.toString("utf8"));
    assert.equal(await page.$eval("#skillDestination", (el) => el.textContent), ".claude/skills/eez-dapp-quickstart/SKILL.md");
    assert.equal(await page.$eval("#skillDialog", (el) => el.textContent.includes("curl ")), false);
    const bounds = await page.$eval("#skillDialog", (el) => {
      const r = el.getBoundingClientRect();
      return { left: r.left, right: r.right, scroll: el.scrollWidth, client: el.clientWidth };
    });
    assert.ok(bounds.left >= 0 && bounds.right <= width && bounds.scroll <= bounds.client, "Skill dialog must fit mobile and desktop");
    await page.evaluate(() => { window.rejectCopy = true; });
    await page.click('[data-copy="file"]');
    await page.waitForFunction(() => document.querySelector('[data-copy="file"]').textContent === "COPY FAILED");
    assert.equal(await page.evaluate(() => window.copied.length), 1);
    await page.keyboard.press("Escape");
    assert.equal(await page.evaluate(() => document.activeElement.className), "skill-open");
    await clean(page, state);
  }
  for (const skillMode of ["tampered", "html", "missing", "redirect"]) {
    const { page, state } = await open(browser, file, { skillMode });
    await page.click(".skill-open");
    await page.waitForFunction(() => document.querySelector("#skillStatus").textContent.startsWith("Could not verify"));
    assert.equal(await page.$eval('[data-copy="file"]', (button) => button.disabled), true);
    await page.$eval('[data-copy="file"]', (button) => button.click());
    assert.deepEqual(await page.evaluate(() => window.copied), []);
    await clean(page, state);
  }
  const { page, state } = await open(browser, file, { clipboardMissing: true });
  await page.click(".skill-open");
  await page.waitForFunction(() => !document.querySelector('[data-copy="file"]').disabled);
  await page.click('[data-copy="file"]');
  assert.equal(await page.$eval('[data-copy="file"]', (button) => button.textContent), "COPY FAILED");
  await clean(page, state);
  console.log("Agent skill copy rejects changed files, HTML errors and redirects; clipboard failures stay visible.");
}

async function deployment(browser) {
  const { page, state } = await open(browser, "deploy.html");
  assert.equal(await page.$eval("#broadcastChoice", (el) => el.open), false);
  const copy = await page.$$("[data-copy-pre]");
  for (const button of copy) {
    if (await button.evaluate((el) => !!el.closest("#broadcastChoice"))) { continue; }
    await button.click();
  }
  const before = await page.evaluate(() => window.copied);
  assert.ok(before.some((text) => text.includes("forge create") && text.includes('--chain-id 696990')));
  assert.ok(before.every((text) => !text.includes("--broadcast")), "Default copy path must not send a transaction");
  await page.click("#broadcastChoice summary");
  await page.click("#broadcastChoice [data-copy-pre]");
  const broadcast = await page.evaluate(() => window.copied.at(-1));
  assert.ok(broadcast.includes('test "$(cast chain-id --rpc-url "$EEZ_RPC")" = "696990" &&'));
  assert.ok(broadcast.includes("--chain-id 696990") && broadcast.includes("--account eez-mainnet --broadcast"));
  assert.ok(!broadcast.includes("--private-key") && !broadcast.includes("--password"));
  assert.ok(!broadcast.includes("$ forge"));
  const text = await page.$eval("body", (body) => body.textContent);
  assert.ok(text.includes("mainnet playground") && text.includes("real ETH"));
  assert.ok(!/demo app on the testnet|PRE-MAINNET|pre-mainnet \(test network\)/.test(text));
  await clean(page, state);
  console.log("Deployment COPY previews first and keeps real-ETH broadcast explicit and chain-bound.");
}

async function main() {
  const browser = await puppeteer.launch(); // Chromium's sandbox stays enabled.
  try { await browsing(browser); await agentSkill(browser); await deployment(browser); }
  finally { await browser.close(); }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
