/**
 * Make the pictures for the DH Launcher App Store listing.
 *
 *   node scripts/store-assets.mjs        # writes store-listing/screenshots/iphone-6.9/en/
 *   node scripts/store-assets.mjs 02     # one slide only
 *
 * Follows the To-Do store pictures (dh-planner: scripts/todo-store-assets.mjs):
 * each slide is a small HTML page with a heading, a few words and a picture of
 * the app, drawn by Chrome. Navy slides for the app, a paper slide for the
 * research and privacy story. Georgia for headings and Futura for words, which
 * a Mac has. Run this on a Mac with Google Chrome.
 *
 * The app pictures are simulator screenshots (iPhone 17 Pro, 1206x2622) in
 * store-listing/source-pictures/. They show only Apple's own apps, and the dock
 * holds only DH Launcher. Take them again when the app changes. drawer.png is
 * the app's own list, used in the README.
 *
 * Size: 1320x2868, the 6.9" iPhone size App Store Connect asks for; it scales
 * these down for smaller iPhones.
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SOURCE = path.join(ROOT, "store-listing/source-pictures");
const OUT = path.join(ROOT, "store-listing/screenshots/iphone-6.9/en");
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const W = 1320;
const H = 2868;

// The colours of the To-Do slides.
const INK = "#2f3a4a";
const NAVY = "#1e2837";
const PAPER = "#edebe7";
const CREAM = "#f4f1ea";

/** Lucide icons (ISC licence), copied in so this script needs no packages. */
const ICONS = {
  "search": "<path d=\"m21 21-4.34-4.34\"/><circle cx=\"11\" cy=\"11\" r=\"8\"/>",
  "layout-list": "<rect width=\"7\" height=\"7\" x=\"3\" y=\"3\" rx=\"1\"/><rect width=\"7\" height=\"7\" x=\"3\" y=\"14\" rx=\"1\"/><path d=\"M14 4h7\"/><path d=\"M14 9h7\"/><path d=\"M14 15h7\"/><path d=\"M14 20h7\"/>",
  "circle-check-big": "<path d=\"M21.801 10A10 10 0 1 1 17 3.335\"/><path d=\"m9 11 3 3L22 4\"/>",
  "brain": "<path d=\"M12 18V5\"/><path d=\"M15 13a4.17 4.17 0 0 1-3-4 4.17 4.17 0 0 1-3 4\"/><path d=\"M17.598 6.5A3 3 0 1 0 12 5a3 3 0 1 0-5.598 1.5\"/><path d=\"M17.997 5.125a4 4 0 0 1 2.526 5.77\"/><path d=\"M18 18a4 4 0 0 0 2-7.464\"/><path d=\"M19.967 17.483A4 4 0 1 1 12 18a4 4 0 1 1-7.967-.517\"/><path d=\"M6 18a4 4 0 0 1-2-7.464\"/><path d=\"M6.003 5.125a4 4 0 0 0-2.526 5.77\"/>",
  "chart-scatter": "<circle cx=\"7.5\" cy=\"7.5\" r=\".5\" fill=\"currentColor\"/><circle cx=\"18.5\" cy=\"5.5\" r=\".5\" fill=\"currentColor\"/><circle cx=\"11.5\" cy=\"11.5\" r=\".5\" fill=\"currentColor\"/><circle cx=\"7.5\" cy=\"16.5\" r=\".5\" fill=\"currentColor\"/><circle cx=\"17.5\" cy=\"14.5\" r=\".5\" fill=\"currentColor\"/><path d=\"M3 3v16a2 2 0 0 0 2 2h16\"/>",
  "code-xml": "<path d=\"m18 16 4-4-4-4\"/><path d=\"m6 8-4 4 4 4\"/><path d=\"m14.5 4-5 16\"/>",
  "lock": "<rect width=\"18\" height=\"11\" x=\"3\" y=\"11\" rx=\"2\" ry=\"2\"/><path d=\"M7 11V7a5 5 0 0 1 10 0v4\"/>",
  "smartphone": "<rect width=\"14\" height=\"20\" x=\"5\" y=\"2\" rx=\"2\" ry=\"2\"/><path d=\"M12 18h.01\"/>",
  "workflow": "<rect width=\"8\" height=\"8\" x=\"3\" y=\"3\" rx=\"2\"/><path d=\"M7 11v4a2 2 0 0 0 2 2h4\"/><rect width=\"8\" height=\"8\" x=\"13\" y=\"13\" rx=\"2\"/>",
  "sliders-horizontal": "<path d=\"M10 5H3\"/><path d=\"M12 19H3\"/><path d=\"M14 3v4\"/><path d=\"M16 17v4\"/><path d=\"M21 12h-9\"/><path d=\"M21 19h-5\"/><path d=\"M21 5h-7\"/><path d=\"M8 10v4\"/><path d=\"M8 12H3\"/>",
};

const icon = (name, size) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICONS[name]}</svg>`;

const picture = (name) => `data:image/png;base64,${fs.readFileSync(path.join(SOURCE, `${name}.png`)).toString("base64")}`;

const BASE_CSS = `
  * { box-sizing: border-box; margin: 0; }
  html, body { width: ${W}px; height: ${H}px; }
  body { font-family: Futura, "Avenir Next", sans-serif; -webkit-font-smoothing: antialiased; overflow: hidden; }
  h1 { font-family: Georgia, "Times New Roman", serif; font-weight: 700; letter-spacing: -0.01em; text-align: center; line-height: 1.08; }
  h2 { font-family: Georgia, serif; font-weight: 400; text-align: center; line-height: 1.2; }
  .slide { position: relative; width: 100%; height: 100%; }
  .phone { position: absolute; left: 50%; transform: translateX(-50%); border-radius: 118px; overflow: hidden;
           box-shadow: 0 0 0 14px #0b0f15, 0 0 0 17px rgba(255,255,255,0.28), 0 50px 120px rgba(0,0,0,0.55); }
  .phone img { display: block; width: 100%; }
`;

/** A navy slide: heading, line under it, optional points, and the phone. */
function appSlide({ heading, sub, points = [], shot, phoneWidth = 860, phoneTop }) {
  const top = phoneTop ?? (points.length ? 1010 : 760);
  return `<!doctype html><meta charset="utf-8"><style>${BASE_CSS}
    body { background: ${NAVY}; color: ${CREAM}; }
    h1 { font-size: 112px; padding: 190px 90px 0; }
    h2 { font-size: 64px; margin-top: 34px; padding: 0 90px; color: rgba(244,241,234,0.86); }
    ul { list-style: none; padding: 0; margin: 64px auto 0; width: max-content; }
    li { display: flex; align-items: center; gap: 26px; font-size: 52px; line-height: 1.75; }
    li svg { width: 54px; height: 54px; flex-shrink: 0; }
    .phone { top: ${top}px; width: ${phoneWidth}px; }
  </style>
  <div class="slide">
    <h1>${heading}</h1>
    <h2>${sub}</h2>
    ${points.length ? `<ul>${points.map(([i, t]) => `<li>${icon(i, 54)}<span>${t}</span></li>`).join("")}</ul>` : ""}
    <div class="phone"><img src="${picture(shot)}"></div>
  </div>`;
}

/** The last slide, as on To-Do: where the app comes from, and what it does with your data. */
function researchSlide() {
  return `<!doctype html><meta charset="utf-8"><style>${BASE_CSS}
    body { background: ${PAPER}; color: ${INK}; }
    h1 { font-size: 112px; text-align: left; padding: 300px 96px 0; }
    h1 span { font-weight: 400; }
    .points { list-style: none; padding: 0; margin: 130px 96px 0; }
    .points li { display: flex; align-items: center; gap: 26px; font-size: 62px; line-height: 1.8; }
    .points svg { width: 60px; height: 60px; flex-shrink: 0; }
    .cards { margin: 170px 96px 0; display: flex; flex-direction: column; gap: 60px; }
    .card { background: #fff; border-radius: 34px; padding: 64px 66px; box-shadow: 0 0 0 2px rgba(47,58,74,0.14), 0 18px 50px rgba(47,58,74,0.08); }
    .card h3 { font-family: Georgia, serif; font-size: 66px; margin-bottom: 30px; }
    .card div { display: flex; gap: 26px; font-size: 47px; line-height: 1.38; color: #4a5565; margin-top: 18px; }
    .card svg { width: 48px; height: 48px; flex-shrink: 0; margin-top: 6px; color: ${INK}; }
  </style>
  <div class="slide">
    <h1>Based on 10+ years of award-winning research <span>on digital distraction</span></h1>
    <ul class="points">
      <li>${icon("circle-check-big", 60)}<span>Backed by psychological theory</span></li>
      <li>${icon("circle-check-big", 60)}<span>Privacy-first by design</span></li>
    </ul>
    <div class="cards">
      <div class="card">
        <h3>Research-based</h3>
        <div>${icon("brain", 48)}<span>DH Launcher is based on research on digital distraction by the Centre for Digital Habits, led by Dr Ulrik Lyngs at the University of Oxford.</span></div>
        <div>${icon("chart-scatter", 48)}<span>digitalhabits.org/research</span></div>
      </div>
      <div class="card">
        <h3>Your data stays with you</h3>
        <div>${icon("lock", 48)}<span>Your list is kept on your iPhone. The app collects zero user data.</span></div>
        <div>${icon("code-xml", 48)}<span>Free, and the source code is open (MIT licence).</span></div>
      </div>
    </div>
  </div>`;
}

// The order of the store listing. The first three show before a person scrolls.
const SLIDES = [
  { id: "01-calm-home-screen", html: () => appSlide({
      heading: "A calm home screen",
      sub: "and apps you open on purpose",
      points: [["smartphone", "Your apps as plain words"], ["layout-list", "Only the ones you choose"], ["search", "The rest stay in iOS Search"]],
      shot: "home", phoneWidth: 780 }) },
  { id: "02-pick-your-apps", html: () => appSlide({
      heading: "Pick your apps in seconds",
      sub: "tick the ones you want on your home screen",
      shot: "picker" }) },
  { id: "03-every-app", html: () => appSlide({
      heading: "Works with every app",
      sub: "a one-step Shortcut opens apps without a link, and the app shows you how",
      shot: "shortcut", phoneTop: 880 }) },
  { id: "04-make-it-yours", html: () => appSlide({
      heading: "Make it yours",
      sub: "font, text size, alignment, lowercase, and a date if you want one",
      shot: "settings", phoneTop: 880 }) },
  { id: "05-research-and-privacy", html: researchSlide },
];

const only = process.argv[2];
fs.mkdirSync(OUT, { recursive: true });
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "dh-launcher-slides-"));
for (const slide of SLIDES) {
  if (only && !slide.id.startsWith(only)) continue;
  const page = path.join(tmp, `${slide.id}.html`);
  fs.writeFileSync(page, slide.html());
  const file = path.join(OUT, `${slide.id}.png`);
  execFileSync(CHROME, [
    "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
    `--window-size=${W},${H}`, `--screenshot=${file}`, `file://${page}`,
  ], { stdio: "ignore" });
  console.log(path.relative(ROOT, file));
}
fs.rmSync(tmp, { recursive: true, force: true });
