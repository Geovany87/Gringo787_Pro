// scripts/seo.js
import globbyPkg from 'globby';
const globby = globbyPkg.globby || globbyPkg;
import { writeFileSync } from 'node:fs';
import { SitemapStream, streamToPromise } from 'sitemap';
import { resolve } from 'node:path';
import { Readable } from 'node:stream';

const isProd = process.env.NODE_ENV === 'production';
const hostname = isProd
  ? 'https://www.gringo787.com'
  : 'http://localhost:5173';

(async () => {
  try {
    const pages = await globby([
      'public/**/*.html',
      '!public/404.html'
    ]);

    const urls = pages.map(page =>
      page.replace(/^public/, '')
          .replace(/index\.html$/, '')
          .replace(/\\/g, '/')
    );

    const sitemapStream = new SitemapStream({ hostname });

    const xml = await streamToPromise(
      Readable.from(urls.map(url => ({ url }))).pipe(sitemapStream)
    );

    const sitemapPath = resolve('public', 'sitemap.xml');
    writeFileSync(sitemapPath, xml.toString());
    console.log(`✅ Sitemap generated at ${sitemapPath} with base ${hostname}`);
  } catch (err) {
    console.error('❌ Error generating sitemap:', err);
    process.exit(1);
  }
})();
