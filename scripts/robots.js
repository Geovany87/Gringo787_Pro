// scripts/robots.js
import fs from 'fs';
import path from 'path';

const isProd = process.env.NODE_ENV === 'production';
const siteUrl = isProd
  ? 'https://www.gringo787.com'
  : 'http://localhost:5173';

const robotsContent = `User-agent: *
Allow: /

Sitemap: ${siteUrl}/sitemap.xml
`;

const publicDir = path.resolve('public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir);
}

fs.writeFileSync(path.join(publicDir, 'robots.txt'), robotsContent);
console.log(`✅ robots.txt generated at ${path.join(publicDir, 'robots.txt')} with base ${siteUrl}`);
