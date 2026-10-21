#!/usr/bin/env node
/* Browser regressions for step navigation and COPY. Run only on CI's sandboxed
 * Chromium; clipboard writes are intercepted and no displayed commands run. */
const assert = require("node:assert/strict");
const path = require("node:path");
const { pathToFileURL } = require("node:url");
const puppeteer = require("puppeteer");

const root = path.resolve(__dirname, "..");
const roundTrip = "dapp-developers/qs1-run-your-first-round-trip.html";
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function open(browser, file, width = 1920) {
  const page = await browser.newPage();
  await page.setViewport({ width, height: width === 1920 ? 1080 : 844 });
  await page.evaluateOnNewDocument(() => {
    window.copied = [];
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: async (text) => { window.copied.push(text); } },
    });
    document.execCommand = (command) => {
      if (command === "copy") {
        window.copied.push(document.activeElement.value);
        return true;
      }
      return false;
    };
  });
  await page.goto(pathToFileURL(path.join(root, file)).href, { waitUntil: "load" });
  await page.click("#btnStart");
  await page.waitForFunction(() => document.getElementById("stepLabel").textContent === "STEP 1 OF 3");
  await delay(120); // Let the mobile scroll-to-top and layout updates finish.
  return page;
}

async function expectStep(page, step) {
  await page.waitForFunction(
    (n) => document.getElementById("stepLabel").textContent === "STEP " + n + " OF 3",
    { timeout: 2000 }, step
  );
  await delay(120);
}

async function navigation(browser, width) {
  const page = await open(browser, roundTrip, width);
  try {
    // These are real pointer clicks faster than the forward button's guard.
    await page.click('#dots button[data-step="1"]');
    await expectStep(page, 2);
    await page.click('#dots button[data-step="2"]');
    await expectStep(page, 3);

    // Dispatch both clicks in one task to avoid timing-dependent double-click
    // assertions on a loaded runner. detail=1 follows the pointer-click path.
    const result = await page.evaluate(() => {
      const click = (selector) => document.querySelector(selector).dispatchEvent(
        new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 })
      );
      const label = () => document.getElementById("stepLabel").textContent;
      click('#dots button[data-step="0"]');
      click("#btnNext");
      const first = label();
      const repeatedAllowed = click("#btnNext");
      const repeated = label();
      // A numbered jump resets the forward gesture.
      click('#dots button[data-step="1"]');
      click("#btnNext");
      const last = label();
      // Keep a regression on this page instead of following an external page.
      document.getElementById("nextDemo").href = "#unexpected-navigation";
      const exitAllowed = click("#nextDemo");
      return { first, repeatedAllowed, repeated, last, exitAllowed };
    });
    assert.deepEqual(result, {
      first: "STEP 2 OF 3", repeatedAllowed: false, repeated: "STEP 2 OF 3",
      last: "STEP 3 OF 3", exitAllowed: false,
    });

    // Hash navigation, then browser Back, must restore the selected steps.
    await page.evaluate(() => { location.hash = "#step-1"; });
    await expectStep(page, 1);
    await page.evaluate(() => { location.hash = "#step-3"; });
    await expectStep(page, 3);
    await page.goBack();
    await expectStep(page, 1);

    // Native keyboard activation uses detail=0 and must not lose steps.
    await page.focus("#btnNext");
    await page.keyboard.press("Enter");
    await expectStep(page, 2);
    await page.keyboard.press("Enter");
    await expectStep(page, 3);
  } finally {
    await page.close();
  }
}

async function copyPanels(browser, width) {
  const page = await open(browser, roundTrip, width);
  try {
    await page.click("#btnCopy");
    assert.equal(await page.evaluate(() => window.copied[0]), [
      "git clone https://github.com/eez-association/eez-core-protocol.git",
      "cd eez-core-protocol",
      "git checkout -q 9a1f815336c20d28e5ec5cecbf195c41fbd5ab0f",
      "git submodule update --init --recursive", "",
    ].join("\n"));

    await page.click('#dots button[data-step="1"]');
    await expectStep(page, 2);
    await page.click("#btnCopy");
    assert.equal(await page.evaluate(() => window.copied[1]),
      "forge build\nbash script/e2e/run/local/parallel.sh counter counterL2\n");

    await page.click('#dots button[data-step="2"]');
    await expectStep(page, 3);
    assert.deepEqual(await page.$eval("#btnCopy", (button) => ({
      hidden: button.hidden, display: getComputedStyle(button).display,
    })), { hidden: true, display: "none" });
    // Even a programmatic activation must not write sample output.
    await page.$eval("#btnCopy", (button) => button.click());
    await delay(30);
    assert.equal(await page.evaluate(() => window.copied.length), 2);

    await page.click('#dots button[data-step="0"]');
    await expectStep(page, 1);
    assert.equal(await page.$eval("#btnCopy", (button) => button.hidden), false);
    await page.click("#btnCopy");
    assert.equal(await page.evaluate(() => window.copied.length), 3);
  } finally {
    await page.close();
  }

  // A page with shell commands can also have real Solidity panels. The lack
  // of "$ " prompts must not hide COPY or change their source.
  for (const [file, expected] of [
    ["dapp-developers/qs7-cross-chain-flash-loan.html", "IERC20(_token).approve(address(bridge), amount);"],
    ["dapp-developers/qs8-bridge-tokens-both-ways.html", "if (msg.sender != expectedProxy) revert UnauthorizedCaller();"],
  ]) {
    const codePage = await open(browser, file, width);
    try {
      await codePage.click('#dots button[data-step="1"]');
      await expectStep(codePage, 2);
      await codePage.click("#btnCopy");
      const copied = await codePage.evaluate(() => window.copied[0]);
      assert.ok(copied.includes(expected), file + ": missing Solidity source");
      assert.ok(!copied.includes("$ git clone"), file + ": copied the wrong step");
    } finally {
      await codePage.close();
    }
  }
}

async function main() {
  const browser = await puppeteer.launch();
  try {
    for (const width of [1920, 390]) {
      await navigation(browser, width);
      await copyPanels(browser, width);
    }
    console.log("Navigation and COPY safeguards pass at desktop and mobile widths.");
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
