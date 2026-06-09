#!/usr/bin/env node
// webfetch -- render any URL with headless Chromium (Playwright) and emit clean
// markdown (Mozilla Readability + Turndown), plain text, or the rendered HTML.
// Local, OSS, no API key, nothing leaves the machine. Handles JS-rendered SPAs.
import { chromium } from 'playwright';
import { Readability } from '@mozilla/readability';
import { JSDOM, VirtualConsole } from 'jsdom';
import TurndownService from 'turndown';
import { writeFileSync } from 'node:fs';

const HELP = `webfetch <url> [options]
  Render a page (JS-aware) and print clean markdown to stdout.

Options:
  -o, --out <file>     write output to a file instead of stdout
  --html               emit rendered post-JS HTML instead of markdown
  --text               emit plain text (Readability) instead of markdown
  --raw                markdown of the whole page (skip main-content extraction)
  --selector <css>     wait for this CSS selector before extracting
  --wait <ms>          extra wait after load settles (default 0)
  --timeout <ms>       navigation timeout (default 45000)
  --screenshot <file>  also save a full-page PNG
  -h, --help           show this help
`;

const args = process.argv.slice(2);
const o = { url: null, out: null, mode: 'markdown', wait: 0, timeout: 45000, selector: null, screenshot: null };
for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === '-h' || a === '--help') { process.stdout.write(HELP); process.exit(0); }
  else if (a === '-o' || a === '--out') o.out = args[++i];
  else if (a === '--html') o.mode = 'html';
  else if (a === '--text') o.mode = 'text';
  else if (a === '--raw') o.mode = 'raw';
  else if (a === '--selector') o.selector = args[++i];
  else if (a === '--wait') o.wait = parseInt(args[++i], 10);
  else if (a === '--timeout') o.timeout = parseInt(args[++i], 10);
  else if (a === '--screenshot') o.screenshot = args[++i];
  else if (!a.startsWith('-') && !o.url) o.url = a;
  else { console.error(`webfetch: unknown arg '${a}'`); process.exit(2); }
}
if (!o.url) { process.stderr.write(HELP); process.exit(2); }

const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
           '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

const browser = await chromium.launch({ headless: true });
try {
  const ctx = await browser.newContext({ userAgent: UA, viewport: { width: 1366, height: 900 }, locale: 'en-US' });
  const page = await ctx.newPage();
  await page.goto(o.url, { waitUntil: 'domcontentloaded', timeout: o.timeout });
  // best-effort: let XHR/fetch settle, but never hang on it
  await page.waitForLoadState('networkidle', { timeout: 8000 }).catch(() => {});
  if (o.selector) await page.waitForSelector(o.selector, { timeout: o.timeout }).catch(() => {});
  if (o.wait) await page.waitForTimeout(o.wait);
  if (o.screenshot) await page.screenshot({ path: o.screenshot, fullPage: true });
  const html = await page.content();
  const finalUrl = page.url();
  await browser.close();

  let out;
  if (o.mode === 'html') {
    out = html;
  } else {
    const vc = new VirtualConsole();
    vc.sendTo(console, { omitJSDOMErrors: true }); // drop noisy non-fatal CSS-parse warnings
    const dom = new JSDOM(html, { url: finalUrl, virtualConsole: vc });
    const td = () => new TurndownService({ headingStyle: 'atx', codeBlockStyle: 'fenced', bulletListMarker: '-' });
    if (o.mode === 'raw') {
      out = td().turndown(dom.window.document.body.innerHTML);
    } else {
      const article = new Readability(dom.window.document).parse();
      if (o.mode === 'text') {
        out = (article?.textContent || dom.window.document.body.textContent || '').trim();
      } else {
        const title = article?.title ? `# ${article.title}\n\n` : '';
        const bodyHtml = article?.content || dom.window.document.body.innerHTML;
        out = `${title}> source: ${finalUrl}\n\n${td().turndown(bodyHtml)}`;
      }
    }
  }

  if (o.out) { writeFileSync(o.out, out); console.error(`webfetch: wrote ${o.out} (${out.length} chars)`); }
  else process.stdout.write(out + '\n');
} catch (e) {
  await browser.close().catch(() => {});
  console.error(`webfetch error: ${e.message}`);
  process.exit(1);
}
