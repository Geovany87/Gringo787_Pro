# Gringo787 Landscaping — Production Website

Professional, bilingual, conversion-first static site with automated SEO and zero-maintenance deployment on Netlify.

## Tech stack
- HTML + Tailwind CSS (CLI build)
- Netlify Forms with honeypot + reCAPTCHA
- GitHub Actions for sitemap.xml + robots.txt
- Zero server dependencies; static deploy

## Quick start
1. npm ci
2. npm run dev (for local CSS watch) or npm run build
3. Open public/index.html

## Deploy
- Netlify: publish "public", command "npm run build"
- Set env var SITE_URL=https://www.gringo787.com in Netlify for correct sitemap links.

## Customize
- Update business details in HTML head JSON-LD (index, about, contact).
- Replace images in public/assets.
- Edit colors/typography in tailwind.config.js.
