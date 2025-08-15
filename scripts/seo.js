import { createWriteStream, existsSync, readFileSync, writeFileSync } from 'fs';
import { SitemapStream } from 'sitemap';
import globby from 'globby';

// SITE_URL should be set in Netlify; falls back to DOMAIN in HTML if not set.
const SITE_URL = process.env.SITE_URL || 'https://www.gringo787.com';
const GLOBS = [
  'public/**/*.html',
  '!public/404.html',
  '!public/**/thanks/index.html' // exclude thank-you from sitemap
];

(async () => {
  const files = await globby(GLOBS);
  const links = files
    .map((p) => p.replace(/^public/, ''))
    .map((url) => {
      const normalized = url.endsWith('/index.html') ? url.replace('/index.html', '/') : url;
      const priority =
        normalized === '/' ? 1.0 :
        normalized.startsWith('/services') || normalized.startsWith('/es/servicios') ? 0.8 :
        normalized.startsWith('/contact') || normalized.startsWith('/es/contacto') ? 0.9 :
        0.7;
      return { url: normalized, changefreq: 'weekly', priority };
    });

  const stream = new SitemapStream({ hostname: SITE_URL });
  const write = createWriteStream('public/sitemap.xml');
  stream.pipe(write);
  links.forEach((l) => stream.write(l));
  stream.end();

  write.on('finish', () => {
    const robotsPath = 'public/robots.txt';
    const desired = `User-agent: *\nAllow: /\nSitemap: ${SITE_URL}/sitemap.xml\n`;
    const current = existsSync(robotsPath) ? readFileSync(robotsPath, 'utf8') : '';
    if (current.trim() !== desired.trim()) writeFileSync(robotsPath, desired, 'utf8');
    console.log('Sitemap and robots updated.');
  });
})();
