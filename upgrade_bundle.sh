#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Configuration (edit or export)
# -------------------------------
BUSINESS_NAME="${BUSINESS_NAME:-Gringo787 Landscaping}"
DOMAIN="${DOMAIN:-https://www.gringo787.com}"
PHONE="${PHONE:-+1-215-555-0137}"
EMAIL="${EMAIL:-hello@gringo787.com}"
CITY="${CITY:-Philadelphia}"
REGION="${REGION:-PA}"
POSTAL="${POSTAL:-19100}"
HOURS_WEEKDAY="${HOURS_WEEKDAY:-08:00-18:00}"
HOURS_SATURDAY="${HOURS_SATURDAY:-09:00-15:00}"

echo "Applying upgrade for $BUSINESS_NAME at $DOMAIN"

# Directories
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p src
mkdir -p public/{assets,about,services,contact,thanks,es,es/servicios,es/contacto,gallery}
mkdir -p public/assets/icons

# -------------------------------
# Root: README
# -------------------------------
cat > README.md <<EOF
# $BUSINESS_NAME — Production Website

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
- Set env var SITE_URL=$DOMAIN in Netlify for correct sitemap links.

## Customize
- Update business details in HTML head JSON-LD (index, about, contact).
- Replace images in public/assets.
- Edit colors/typography in tailwind.config.js.
EOF

# -------------------------------
# package.json
# -------------------------------
cat > package.json <<'EOF'
{
  "name": "gringo787_pro",
  "private": true,
  "version": "1.0.0",
  "description": "Gringo787 Landscaping website",
  "scripts": {
    "dev": "tailwindcss -i src/styles.css -o public/styles.css --watch",
    "build:css": "tailwindcss -i src/styles.css -o public/styles.css --minify",
    "seo:update": "node scripts/seo.js",
    "build": "npm run build:css && node scripts/seo.js"
  },
  "dependencies": {
    "globby": "^14.0.1",
    "sitemap": "^7.1.2"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.13",
    "prettier": "^3.3.3"
  }
}
EOF

# -------------------------------
# Tailwind config
# -------------------------------
cat > tailwind.config.js <<'EOF'
// Tailwind config: brand palette + typography
module.exports = {
  content: ["./public/**/*.html"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#e8fff2",
          100: "#c8ffd1",
          200: "#97f7aa",
          300: "#63e287",
          400: "#35c56a",
          500: "#18a651",
          600: "#0f8642",
          700: "#0c6935",
          800: "#0a512a",
          900: "#073a1f"
        },
        dark: "#0e1116"
      },
      fontFamily: {
        display: ["Poppins", "ui-sans-serif", "system-ui"],
        body: ["Inter", "ui-sans-serif", "system-ui"]
      },
      boxShadow: {
        soft: "0 10px 30px -10px rgba(0,0,0,0.25)"
      }
    }
  },
  plugins: []
}
EOF

# -------------------------------
# Prettier config
# -------------------------------
cat > .prettierrc.json <<'EOF'
{
  "printWidth": 100,
  "singleQuote": true,
  "semi": true
}
EOF

# -------------------------------
# .gitignore
# -------------------------------
cat > .gitignore <<'EOF'
node_modules
.DS_Store
*.log
dist
EOF

# -------------------------------
# Netlify config
# -------------------------------
cat > netlify.toml <<'EOF'
[build]
  publish = "public"
  command = "npm run build"

[[redirects]]
  from = "/*"
  to = "/404.html"
  status = 404

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Permissions-Policy = "geolocation=(), camera=(), microphone=()"
EOF

# -------------------------------
# Tailwind source CSS
# -------------------------------
cat > src/styles.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Base */
@layer base {
  html { scroll-behavior: smooth; }
  body { @apply font-body text-neutral-800 bg-white; }
}

/* Components */
@layer components {
  .btn-primary { @apply inline-flex items-center rounded-md bg-brand-500 px-5 py-3 text-white hover:bg-brand-600 transition shadow-soft; }
  .btn-secondary { @apply inline-flex items-center rounded-md bg-white text-brand-700 border border-brand-200 px-5 py-3 hover:bg-brand-50; }
  .card { @apply rounded-xl border border-neutral-200 p-6 hover:shadow-soft transition bg-white; }
  .container-xl { @apply max-w-6xl mx-auto px-4; }
  .section { @apply py-14 md:py-20; }
  .muted { @apply text-neutral-600; }
  .nav-link { @apply text-sm md:text-base text-neutral-700 hover:text-brand-700; }
}
EOF

# -------------------------------
# SEO automation script
# -------------------------------
cat > scripts/seo.js <<'EOF'
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
EOF

# -------------------------------
# GitHub Action workflow
# -------------------------------
cat > .github/workflows/update-seo.yml <<'EOF'
name: Update SEO files
on:
  push:
    branches: [ main ]
  workflow_dispatch: {}
permissions:
  contents: write
jobs:
  seo:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - name: Install
        run: npm ci
      - name: Generate sitemap and robots
        run: npm run seo:update
      - name: Commit and push
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            git config user.name "gringo-bot"
            git config user.email "actions@users.noreply.github.com"
            git add public/sitemap.xml public/robots.txt
            git commit -m "chore(seo): auto-update sitemap and robots"
            git push
          fi
EOF

# -------------------------------
# Favicon, manifest, OG image placeholders
# -------------------------------
cat > public/assets/icons/favicon.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="12" fill="#18a651"/>
  <path d="M18 40c10-2 14-10 14-16 5 6 4 16-4 22 6 0 12-3 18-10-2 12-12 18-24 18-6 0-9-3-9-6 0-3 2-6 5-8z" fill="white"/>
</svg>
EOF

cat > public/site.webmanifest <<EOF
{
  "name": "$BUSINESS_NAME",
  "short_name": "Gringo787",
  "icons": [
    { "src": "/assets/icons/favicon.svg", "sizes": "64x64", "type": "image/svg+xml", "purpose": "any" }
  ],
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#18a651",
  "background_color": "#ffffff"
}
EOF

# OG cover placeholder
cat > public/assets/og-cover.txt <<'EOF'
Replace this file with an image at public/og-cover.jpg (1200x630 recommended).
EOF

# -------------------------------
# Shared HTML head snippet (function to generate pages)
# -------------------------------
make_head () {
cat <<EOF
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$BUSINESS_NAME | Premium Landscaping in $CITY</title>
  <meta name="description" content="Lawn care, clean-ups, and seasonal maintenance in $CITY. Licensed, insured, and on-time." />
  <link rel="canonical" href="$DOMAIN/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link rel="manifest" href="/site.webmanifest" />
  <link rel="preload" href="/styles.css" as="style" />
  <link href="/styles.css" rel="stylesheet" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="$BUSINESS_NAME" />
  <meta property="og:description" content="Premium landscaping in $CITY—book same-week service today." />
  <meta property="og:url" content="$DOMAIN/" />
  <meta property="og:image" content="$DOMAIN/og-cover.jpg" />
  <meta name="twitter:card" content="summary_large_image" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "LandscapingBusiness",
    "name": "$BUSINESS_NAME",
    "image": "$DOMAIN/og-cover.jpg",
    "url": "$DOMAIN/",
    "telephone": "$PHONE",
    "priceRange": "$$",
    "areaServed": [{"@type": "City","name": "$CITY"}],
    "address": {"@type": "PostalAddress","addressLocality": "$CITY","addressRegion": "$REGION","postalCode": "$POSTAL","addressCountry": "US"},
    "openingHoursSpecification": [
      {"@type": "OpeningHoursSpecification","dayOfWeek":["Monday","Tuesday","Wednesday","Thursday","Friday"],"opens":"${HOURS_WEEKDAY%-*}","closes":"${HOURS_WEEKDAY#*-}"},
      {"@type": "OpeningHoursSpecification","dayOfWeek":"Saturday","opens":"${HOURS_SATURDAY%-*}","closes":"${HOURS_SATURDAY#*-}"}
    ],
    "sameAs": []
  }
  </script>
EOF
}

# Nav and footer partials
NAV=$(cat <<'EOF'
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/services/">Services</a>
      <a class="nav-link" href="/gallery/">Gallery</a>
      <a class="nav-link" href="/about/">About</a>
      <a class="nav-link" href="/contact/">Contact</a>
      <a class="nav-link" href="/es/">ES</a>
      <a class="btn-primary" href="/contact/">Get a free quote</a>
    </nav>
  </div>
</header>
EOF
)

FOOTER=$(cat <<EOF
<footer class="mt-20 border-t">
  <div class="container-xl py-10 grid md:grid-cols-3 gap-8">
    <div>
      <h4 class="font-display font-semibold mb-2">$BUSINESS_NAME</h4>
      <p class="muted">Licensed & insured • Se habla español</p>
      <p class="mt-2"><a class="nav-link" href="tel:$PHONE">$PHONE</a> · <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a></p>
    </div>
    <div>
      <h5 class="font-semibold mb-2">Services</h5>
      <ul class="space-y-1 muted">
        <li><a href="/services/#lawn" class="nav-link">Lawn mowing</a></li>
        <li><a href="/services/#cleanup" class="nav-link">Clean-ups</a></li>
        <li><a href="/services/#mulch" class="nav-link">Mulch</a></li>
        <li><a href="/services/#hedge" class="nav-link">Hedge trimming</a></li>
      </ul>
    </div>
    <div>
      <h5 class="font-semibold mb-2">Company</h5>
      <ul class="space-y-1 muted">
        <li><a href="/about/" class="nav-link">About</a></li>
        <li><a href="/contact/" class="nav-link">Contact</a></li>
        <li><a href="/gallery/" class="nav-link">Gallery</a></li>
      </ul>
    </div>
  </div>
  <div class="border-t">
    <div class="container-xl py-6 text-sm flex items-center justify-between muted">
      <span>© $(date +%Y) $BUSINESS_NAME</span>
      <span>Site by Geovany Cardoza — StratagenAI</span>
    </div>
  </div>
</footer>
EOF
)

# -------------------------------
# Home (EN)
# -------------------------------
cat > public/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
$(make_head)
</head>
<body>
$NAV

<section class="section">
  <div class="container-xl grid md:grid-cols-2 gap-10 items-center">
    <div>
      <h1 class="font-display text-4xl md:text-5xl font-semibold">Premium landscaping in $CITY — same-week service</h1>
      <p class="mt-4 text-lg muted">Lawn care, clean-ups, and seasonal maintenance done right. Licensed, insured, and on-time—every time. Se habla español.</p>
      <div class="mt-6 flex gap-4">
        <a href="/contact/" class="btn-primary">Get a free quote</a>
        <a href="/services/" class="btn-secondary">Explore services</a>
      </div>
      <div class="mt-6 text-sm muted">Serving $CITY and surrounding suburbs.</div>
    </div>
    <div>
      <img src="/assets/hero.webp" alt="Freshly maintained lawn and garden" class="w-full rounded-xl shadow-soft" loading="eager" />
    </div>
  </div>
</section>

<section class="section bg-[rgb(249,250,251)]">
  <div class="container-xl">
    <div class="grid md:grid-cols-4 gap-6">
      <div class="card">
        <h3 class="font-display text-xl mb-2">Lawn mowing</h3>
        <p class="muted">Weekly/biweekly mowing, edging, and sweep.</p>
        <a href="/services/#lawn" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Clean-ups</h3>
        <p class="muted">Spring/fall clean-ups and debris haul-away.</p>
        <a href="/services/#cleanup" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Mulch</h3>
        <p class="muted">Bed prep, fabric, and premium mulch install.</p>
        <a href="/services/#mulch" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Hedge trimming</h3>
        <p class="muted">Clean lines and proper shaping.</p>
        <a href="/services/#hedge" class="nav-link">Learn more →</a>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container-xl grid md:grid-cols-3 gap-6">
    <figure class="card"><blockquote>“Fast, clean, and professional. Best in Philly.”</blockquote><figcaption class="mt-3 muted">— Alicia R., Fishtown</figcaption></figure>
    <figure class="card"><blockquote>“They handled our spring clean-up and it looks amazing.”</blockquote><figcaption class="mt-3 muted">— Mike D., South Philly</figcaption></figure>
    <figure class="card"><blockquote>“On time, fair price, great quality.”</blockquote><figcaption class="mt-3 muted">— Priya S., Manayunk</figcaption></figure>
  </div>
</section>

$FOOTER
</body>
</html>
EOF

# -------------------------------
# Services (EN)
# -------------------------------
cat > public/services/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Services | Gringo787 Landscaping</title>
  <meta name="description" content="Lawn mowing, clean-ups, mulch, and hedge trimming—professional landscaping services." />
  <link rel="canonical" href="https://www.gringo787.com/services/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/services/">Services</a>
      <a class="nav-link" href="/gallery/">Gallery</a>
      <a class="nav-link" href="/about/">About</a>
      <a class="nav-link" href="/contact/">Contact</a>
      <a class="nav-link" href="/es/">ES</a>
      <a class="btn-primary" href="/contact/">Get a free quote</a>
    </nav>
  </div>
</header>

<main class="section container-xl space-y-14">
  <section id="lawn">
    <h1 class="font-display text-3xl font-semibold mb-3">Lawn mowing</h1>
    <p class="muted mb-4">Weekly/biweekly mowing, edging, and blow-off. Seasonal plan options.</p>
    <ul class="list-disc pl-5 muted">
      <li>Includes trimming around edges and obstacles.</li>
      <li>Bagging available on request.</li>
    </ul>
  </section>

  <section id="cleanup">
    <h2 class="font-display text-2xl font-semibold mb-3">Clean-ups</h2>
    <p class="muted mb-4">Spring/fall clean-ups, leaf removal, storm debris haul-away.</p>
  </section>

  <section id="mulch">
    <h2 class="font-display text-2xl font-semibold mb-3">Mulch</h2>
    <p class="muted mb-4">Bed prep, landscape fabric, and premium mulch colors.</p>
  </section>

  <section id="hedge">
    <h2 class="font-display text-2xl font-semibold mb-3">Hedge trimming</h2>
    <p class="muted mb-4">Clean lines, shaping, and debris haul-away included.</p>
  </section>

  <div class="mt-6">
    <a class="btn-primary" href="/contact/">Request a quote</a>
  </div>
</main>

<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Contact (EN) with Netlify Forms
# -------------------------------
cat > public/contact/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  $(make_head)
</head>
<body>
$NAV

<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Request a free quote</h1>
  <form name="quote" method="POST" action="/thanks/" data-netlify="true" data-netlify-recaptcha="true" netlify-honeypot="bot-field" class="grid md:grid-cols-2 gap-6">
    <input type="hidden" name="form-name" value="quote" />
    <p class="hidden">
      <label>Don’t fill this out if you're human: <input name="bot-field" /></label>
    </p>

    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Full name</label>
      <input class="w-full border rounded-md p-3" type="text" name="name" placeholder="Full name" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Phone</label>
      <input class="w-full border rounded-md p-3" type="tel" name="phone" placeholder="Phone" required />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Service address</label>
      <input class="w-full border rounded-md p-3" type="text" name="address" placeholder="Address" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Service</label>
      <select class="w-full border rounded-md p-3" name="service" required>
        <option value="">Select a service</option>
        <option>Lawn mowing</option>
        <option>Clean-up</option>
        <option>Mulch</option>
        <option>Hedge trimming</option>
      </select>
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Email (optional)</label>
      <input class="w-full border rounded-md p-3" type="email" name="email" placeholder="you@email.com" />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Details</label>
      <textarea class="w-full border rounded-md p-3" name="details" rows="5" placeholder="Tell us what you need"></textarea>
    </div>
    <div class="md:col-span-2">
      <div data-netlify-recaptcha="true"></div>
    </div>
    <div class="md:col-span-2">
      <button class="btn-primary" type="submit">Request quote</button>
    </div>
  </form>

  <div class="mt-10 muted">
    Prefer phone? <a class="nav-link" href="tel:$PHONE">$PHONE</a> · Email <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a>
  </div>
</main>

$FOOTER
</body>
</html>
EOF

# -------------------------------
# About (EN)
# -------------------------------
cat > public/about/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  $(make_head)
</head>
<body>
$NAV
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">About $BUSINESS_NAME</h1>
  <p class="muted max-w-3xl">We deliver premium landscaping in $CITY with a focus on reliability, clean finishes, and clear communication. Licensed and insured. Same-week availability in peak season.</p>
  <div class="grid md:grid-cols-2 gap-8 mt-10">
    <div class="card">
      <h2 class="font-display text-xl mb-2">Our promise</h2>
      <p class="muted">On-time arrival, careful work, and a spotless clean-up. If something’s not right, we make it right.</p>
    </div>
    <div class="card">
      <h2 class="font-display text-xl mb-2">Service area</h2>
      <p class="muted">$CITY, South Jersey, and surrounding suburbs.</p>
    </div>
  </div>
</main>
$FOOTER
</body>
</html>
EOF

# -------------------------------
# Gallery (stub)
# -------------------------------
cat > public/gallery/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Gallery | Gringo787 Landscaping</title>
  <meta name="description" content="Before and after landscaping projects." />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Project gallery</h1>
  <p class="muted">Add photos to <code>public/assets/gallery</code> and reference them here.</p>
</main>
<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Home
# -------------------------------
cat > public/es/index.html <<EOF
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$BUSINESS_NAME | Jardinería profesional en $CITY</title>
  <meta name="description" content="Césped, limpiezas y mantenimiento estacional en $CITY. Licenciados, asegurados y puntuales." />
  <link rel="canonical" href="$DOMAIN/es/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="$BUSINESS_NAME" />
  <meta property="og:description" content="Jardinería premium en $CITY—reserve servicio para esta semana." />
  <meta property="og:url" content="$DOMAIN/es/" />
  <meta property="og:image" content="$DOMAIN/og-cover.jpg" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/es/servicios/">Servicios</a>
      <a class="nav-link" href="/es/contacto/">Contacto</a>
      <a class="nav-link" href="/">EN</a>
      <a class="btn-primary" href="/es/contacto/">Pedir cotización</a>
    </nav>
  </div>
</header>

<section class="section">
  <div class="container-xl grid md:grid-cols-2 gap-10 items-center">
    <div>
      <h1 class="font-display text-4xl md:text-5xl font-semibold">Jardinería premium en $CITY — servicio en la misma semana</h1>
      <p class="mt-4 text-lg muted">Césped, limpiezas y mantenimiento estacional. Licenciados, asegurados y puntuales. Se habla español.</p>
      <div class="mt-6 flex gap-4">
        <a href="/es/contacto/" class="btn-primary">Pedir cotización</a>
        <a href="/es/servicios/" class="btn-secondary">Ver servicios</a>
      </div>
    </div>
    <div>
      <img src="/assets/hero.webp" alt="Césped recién mantenido" class="w-full rounded-xl shadow-soft" loading="eager" />
    </div>
  </div>
</section>

<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© $BUSINESS_NAME</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Services
# -------------------------------
cat > public/es/servicios/index.html <<'EOF'
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Servicios | Gringo787 Landscaping</title>
  <meta name="description" content="Corte de césped, limpiezas, mulch y poda." />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>
<main class="section container-xl space-y-14">
  <section id="lawn">
    <h1 class="font-display text-3xl font-semibold mb-3">Corte de césped</h1>
    <p class="muted mb-4">Semanal o quincenal, bordes y limpieza final.</p>
  </section>
  <section id="cleanup">
    <h2 class="font-display text-2xl font-semibold mb-3">Limpiezas</h2>
    <p class="muted mb-4">Primavera/otoño, hojas y escombros.</p>
  </section>
  <section id="mulch">
    <h2 class="font-display text-2xl font-semibold mb-3">Mulch</h2>
    <p class="muted mb-4">Preparación de camas y mulch premium.</p>
  </section>
  <section id="hedge">
    <h2 class="font-display text-2xl font-semibold mb-3">Poda</h2>
    <p class="muted mb-4">Líneas limpias y formado correcto.</p>
  </section>
  <div class="mt-6">
    <a class="btn-primary" href="/es/contacto/">Pedir cotización</a>
  </div>
</main>
<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Contact
# -------------------------------
cat > public/es/contacto/index.html <<EOF
<!doctype html>
<html lang="es">
<head>
  $(make_head)
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>

<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Solicitar cotización</h1>
  <form name="cotizacion" method="POST" action="/thanks/" data-netlify="true" data-netlify-recaptcha="true" netlify-honeypot="campo-bot" class="grid md:grid-cols-2 gap-6">
    <input type="hidden" name="form-name" value="cotizacion" />
    <p class="hidden">
      <label>No completar si eres humano: <input name="campo-bot" /></label>
    </p>

    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Nombre completo</label>
      <input class="w-full border rounded-md p-3" type="text" name="nombre" placeholder="Nombre completo" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Teléfono</label>
      <input class="w-full border rounded-md p-3" type="tel" name="telefono" placeholder="Teléfono" required />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Dirección de servicio</label>
      <input class="w-full border rounded-md p-3" type="text" name="direccion" placeholder="Dirección" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Servicio</label>
      <select class="w-full border rounded-md p-3" name="servicio" required>
        <option value="">Seleccionar</option>
        <option>Corte de césped</option>
        <option>Limpieza</option>
        <option>Mulch</option>
        <option>Poda</option>
      </select>
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Correo (opcional)</label>
      <input class="w-full border rounded-md p-3" type="email" name="correo" placeholder="tu@email.com" />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Detalles</label>
      <textarea class="w-full border rounded-md p-3" name="detalles" rows="5" placeholder="Cuéntanos"></textarea>
    </div>
    <div class="md:col-span-2">
      <div data-netlify-recaptcha="true"></div>
    </div>
    <div class="md:col-span-2">
      <button class="btn-primary" type="submit">Enviar</button>
    </div>
  </form>

  <div class="mt-10 muted">
    También por teléfono <a class="nav-link" href="tel:$PHONE">$PHONE</a> · Email <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a>
  </div>
</main>

<footer class="mt-20 border-t"><div class="container-xl py-10 text-sm muted">© $BUSINESS_NAME</div></footer>
</body>
</html>
EOF

# -------------------------------
# Thanks and 404
# -------------------------------
cat > public/thanks/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Thanks | Gringo787 Landscaping</title>
  <meta name="robots" content="noindex" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">Thanks for reaching out!</h1>
  <p class="muted">We received your request and will get back to you soon.</p>
  <a href="/" class="btn-primary mt-6 inline-flex">Back to home</a>
</main>
</body>
</html>
EOF

cat > public/404.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Not found | Gringo787 Landscaping</title>
  <meta name="robots" content="noindex" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">Page not found</h1>
  <p class="muted">The page you're looking for doesn’t exist.</p>
  <a href="/" class="btn-primary mt-6 inline-flex">Go home</a>
</main>
</body>
</html>
EOF

# -------------------------------
# Robots (initial) — will be kept up to date by CI
# -------------------------------
cat > public/robots.txt <<EOF
User-agent: *
Allow: /
Sitemap: $DOMAIN/sitemap.xml
EOF

# Touch sitemap (CI will regenerate)
echo "<!-- generated by CI -->" > public/sitemap.xml

echo "Upgrade bundle created. Next steps:
1) npm ci
2) npm run build
3) Review public/ and commit."
#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Configuration (edit or export)
# -------------------------------
BUSINESS_NAME="${BUSINESS_NAME:-Gringo787 Landscaping}"
DOMAIN="${DOMAIN:-https://www.gringo787.com}"
PHONE="${PHONE:-+1-215-555-0137}"
EMAIL="${EMAIL:-hello@gringo787.com}"
CITY="${CITY:-Philadelphia}"
REGION="${REGION:-PA}"
POSTAL="${POSTAL:-19100}"
HOURS_WEEKDAY="${HOURS_WEEKDAY:-08:00-18:00}"
HOURS_SATURDAY="${HOURS_SATURDAY:-09:00-15:00}"

echo "Applying upgrade for $BUSINESS_NAME at $DOMAIN"

# Directories
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p src
mkdir -p public/{assets,about,services,contact,thanks,es,es/servicios,es/contacto,gallery}
mkdir -p public/assets/icons

# -------------------------------
# Root: README
# -------------------------------
cat > README.md <<EOF
# $BUSINESS_NAME — Production Website

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
- Set env var SITE_URL=$DOMAIN in Netlify for correct sitemap links.

## Customize
- Update business details in HTML head JSON-LD (index, about, contact).
- Replace images in public/assets.
- Edit colors/typography in tailwind.config.js.
EOF

# -------------------------------
# package.json
# -------------------------------
cat > package.json <<'EOF'
{
  "name": "gringo787_pro",
  "private": true,
  "version": "1.0.0",
  "description": "Gringo787 Landscaping website",
  "scripts": {
    "dev": "tailwindcss -i src/styles.css -o public/styles.css --watch",
    "build:css": "tailwindcss -i src/styles.css -o public/styles.css --minify",
    "seo:update": "node scripts/seo.js",
    "build": "npm run build:css && node scripts/seo.js"
  },
  "dependencies": {
    "globby": "^14.0.1",
    "sitemap": "^7.1.2"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.13",
    "prettier": "^3.3.3"
  }
}
EOF

# -------------------------------
# Tailwind config
# -------------------------------
cat > tailwind.config.js <<'EOF'
// Tailwind config: brand palette + typography
module.exports = {
  content: ["./public/**/*.html"],
  theme: {
    extend: {
      colors: {
        brand: {
          50: "#e8fff2",
          100: "#c8ffd1",
          200: "#97f7aa",
          300: "#63e287",
          400: "#35c56a",
          500: "#18a651",
          600: "#0f8642",
          700: "#0c6935",
          800: "#0a512a",
          900: "#073a1f"
        },
        dark: "#0e1116"
      },
      fontFamily: {
        display: ["Poppins", "ui-sans-serif", "system-ui"],
        body: ["Inter", "ui-sans-serif", "system-ui"]
      },
      boxShadow: {
        soft: "0 10px 30px -10px rgba(0,0,0,0.25)"
      }
    }
  },
  plugins: []
}
EOF

# -------------------------------
# Prettier config
# -------------------------------
cat > .prettierrc.json <<'EOF'
{
  "printWidth": 100,
  "singleQuote": true,
  "semi": true
}
EOF

# -------------------------------
# .gitignore
# -------------------------------
cat > .gitignore <<'EOF'
node_modules
.DS_Store
*.log
dist
EOF

# -------------------------------
# Netlify config
# -------------------------------
cat > netlify.toml <<'EOF'
[build]
  publish = "public"
  command = "npm run build"

[[redirects]]
  from = "/*"
  to = "/404.html"
  status = 404

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Permissions-Policy = "geolocation=(), camera=(), microphone=()"
EOF

# -------------------------------
# Tailwind source CSS
# -------------------------------
cat > src/styles.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Base */
@layer base {
  html { scroll-behavior: smooth; }
  body { @apply font-body text-neutral-800 bg-white; }
}

/* Components */
@layer components {
  .btn-primary { @apply inline-flex items-center rounded-md bg-brand-500 px-5 py-3 text-white hover:bg-brand-600 transition shadow-soft; }
  .btn-secondary { @apply inline-flex items-center rounded-md bg-white text-brand-700 border border-brand-200 px-5 py-3 hover:bg-brand-50; }
  .card { @apply rounded-xl border border-neutral-200 p-6 hover:shadow-soft transition bg-white; }
  .container-xl { @apply max-w-6xl mx-auto px-4; }
  .section { @apply py-14 md:py-20; }
  .muted { @apply text-neutral-600; }
  .nav-link { @apply text-sm md:text-base text-neutral-700 hover:text-brand-700; }
}
EOF

# -------------------------------
# SEO automation script
# -------------------------------
cat > scripts/seo.js <<'EOF'
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
EOF

# -------------------------------
# GitHub Action workflow
# -------------------------------
cat > .github/workflows/update-seo.yml <<'EOF'
name: Update SEO files
on:
  push:
    branches: [ main ]
  workflow_dispatch: {}
permissions:
  contents: write
jobs:
  seo:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - name: Install
        run: npm ci
      - name: Generate sitemap and robots
        run: npm run seo:update
      - name: Commit and push
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            git config user.name "gringo-bot"
            git config user.email "actions@users.noreply.github.com"
            git add public/sitemap.xml public/robots.txt
            git commit -m "chore(seo): auto-update sitemap and robots"
            git push
          fi
EOF

# -------------------------------
# Favicon, manifest, OG image placeholders
# -------------------------------
cat > public/assets/icons/favicon.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <rect width="64" height="64" rx="12" fill="#18a651"/>
  <path d="M18 40c10-2 14-10 14-16 5 6 4 16-4 22 6 0 12-3 18-10-2 12-12 18-24 18-6 0-9-3-9-6 0-3 2-6 5-8z" fill="white"/>
</svg>
EOF

cat > public/site.webmanifest <<EOF
{
  "name": "$BUSINESS_NAME",
  "short_name": "Gringo787",
  "icons": [
    { "src": "/assets/icons/favicon.svg", "sizes": "64x64", "type": "image/svg+xml", "purpose": "any" }
  ],
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#18a651",
  "background_color": "#ffffff"
}
EOF

# OG cover placeholder
cat > public/assets/og-cover.txt <<'EOF'
Replace this file with an image at public/og-cover.jpg (1200x630 recommended).
EOF

# -------------------------------
# Shared HTML head snippet (function to generate pages)
# -------------------------------
make_head () {
cat <<EOF
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$BUSINESS_NAME | Premium Landscaping in $CITY</title>
  <meta name="description" content="Lawn care, clean-ups, and seasonal maintenance in $CITY. Licensed, insured, and on-time." />
  <link rel="canonical" href="$DOMAIN/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link rel="manifest" href="/site.webmanifest" />
  <link rel="preload" href="/styles.css" as="style" />
  <link href="/styles.css" rel="stylesheet" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="$BUSINESS_NAME" />
  <meta property="og:description" content="Premium landscaping in $CITY—book same-week service today." />
  <meta property="og:url" content="$DOMAIN/" />
  <meta property="og:image" content="$DOMAIN/og-cover.jpg" />
  <meta name="twitter:card" content="summary_large_image" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "LandscapingBusiness",
    "name": "$BUSINESS_NAME",
    "image": "$DOMAIN/og-cover.jpg",
    "url": "$DOMAIN/",
    "telephone": "$PHONE",
    "priceRange": "$$",
    "areaServed": [{"@type": "City","name": "$CITY"}],
    "address": {"@type": "PostalAddress","addressLocality": "$CITY","addressRegion": "$REGION","postalCode": "$POSTAL","addressCountry": "US"},
    "openingHoursSpecification": [
      {"@type": "OpeningHoursSpecification","dayOfWeek":["Monday","Tuesday","Wednesday","Thursday","Friday"],"opens":"${HOURS_WEEKDAY%-*}","closes":"${HOURS_WEEKDAY#*-}"},
      {"@type": "OpeningHoursSpecification","dayOfWeek":"Saturday","opens":"${HOURS_SATURDAY%-*}","closes":"${HOURS_SATURDAY#*-}"}
    ],
    "sameAs": []
  }
  </script>
EOF
}

# Nav and footer partials
NAV=$(cat <<'EOF'
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/services/">Services</a>
      <a class="nav-link" href="/gallery/">Gallery</a>
      <a class="nav-link" href="/about/">About</a>
      <a class="nav-link" href="/contact/">Contact</a>
      <a class="nav-link" href="/es/">ES</a>
      <a class="btn-primary" href="/contact/">Get a free quote</a>
    </nav>
  </div>
</header>
EOF
)

FOOTER=$(cat <<EOF
<footer class="mt-20 border-t">
  <div class="container-xl py-10 grid md:grid-cols-3 gap-8">
    <div>
      <h4 class="font-display font-semibold mb-2">$BUSINESS_NAME</h4>
      <p class="muted">Licensed & insured • Se habla español</p>
      <p class="mt-2"><a class="nav-link" href="tel:$PHONE">$PHONE</a> · <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a></p>
    </div>
    <div>
      <h5 class="font-semibold mb-2">Services</h5>
      <ul class="space-y-1 muted">
        <li><a href="/services/#lawn" class="nav-link">Lawn mowing</a></li>
        <li><a href="/services/#cleanup" class="nav-link">Clean-ups</a></li>
        <li><a href="/services/#mulch" class="nav-link">Mulch</a></li>
        <li><a href="/services/#hedge" class="nav-link">Hedge trimming</a></li>
      </ul>
    </div>
    <div>
      <h5 class="font-semibold mb-2">Company</h5>
      <ul class="space-y-1 muted">
        <li><a href="/about/" class="nav-link">About</a></li>
        <li><a href="/contact/" class="nav-link">Contact</a></li>
        <li><a href="/gallery/" class="nav-link">Gallery</a></li>
      </ul>
    </div>
  </div>
  <div class="border-t">
    <div class="container-xl py-6 text-sm flex items-center justify-between muted">
      <span>© $(date +%Y) $BUSINESS_NAME</span>
      <span>Site by Geovany Cardoza — StratagenAI</span>
    </div>
  </div>
</footer>
EOF
)

# -------------------------------
# Home (EN)
# -------------------------------
cat > public/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
$(make_head)
</head>
<body>
$NAV

<section class="section">
  <div class="container-xl grid md:grid-cols-2 gap-10 items-center">
    <div>
      <h1 class="font-display text-4xl md:text-5xl font-semibold">Premium landscaping in $CITY — same-week service</h1>
      <p class="mt-4 text-lg muted">Lawn care, clean-ups, and seasonal maintenance done right. Licensed, insured, and on-time—every time. Se habla español.</p>
      <div class="mt-6 flex gap-4">
        <a href="/contact/" class="btn-primary">Get a free quote</a>
        <a href="/services/" class="btn-secondary">Explore services</a>
      </div>
      <div class="mt-6 text-sm muted">Serving $CITY and surrounding suburbs.</div>
    </div>
    <div>
      <img src="/assets/hero.webp" alt="Freshly maintained lawn and garden" class="w-full rounded-xl shadow-soft" loading="eager" />
    </div>
  </div>
</section>

<section class="section bg-[rgb(249,250,251)]">
  <div class="container-xl">
    <div class="grid md:grid-cols-4 gap-6">
      <div class="card">
        <h3 class="font-display text-xl mb-2">Lawn mowing</h3>
        <p class="muted">Weekly/biweekly mowing, edging, and sweep.</p>
        <a href="/services/#lawn" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Clean-ups</h3>
        <p class="muted">Spring/fall clean-ups and debris haul-away.</p>
        <a href="/services/#cleanup" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Mulch</h3>
        <p class="muted">Bed prep, fabric, and premium mulch install.</p>
        <a href="/services/#mulch" class="nav-link">Learn more →</a>
      </div>
      <div class="card">
        <h3 class="font-display text-xl mb-2">Hedge trimming</h3>
        <p class="muted">Clean lines and proper shaping.</p>
        <a href="/services/#hedge" class="nav-link">Learn more →</a>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container-xl grid md:grid-cols-3 gap-6">
    <figure class="card"><blockquote>“Fast, clean, and professional. Best in Philly.”</blockquote><figcaption class="mt-3 muted">— Alicia R., Fishtown</figcaption></figure>
    <figure class="card"><blockquote>“They handled our spring clean-up and it looks amazing.”</blockquote><figcaption class="mt-3 muted">— Mike D., South Philly</figcaption></figure>
    <figure class="card"><blockquote>“On time, fair price, great quality.”</blockquote><figcaption class="mt-3 muted">— Priya S., Manayunk</figcaption></figure>
  </div>
</section>

$FOOTER
</body>
</html>
EOF

# -------------------------------
# Services (EN)
# -------------------------------
cat > public/services/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Services | Gringo787 Landscaping</title>
  <meta name="description" content="Lawn mowing, clean-ups, mulch, and hedge trimming—professional landscaping services." />
  <link rel="canonical" href="https://www.gringo787.com/services/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/services/">Services</a>
      <a class="nav-link" href="/gallery/">Gallery</a>
      <a class="nav-link" href="/about/">About</a>
      <a class="nav-link" href="/contact/">Contact</a>
      <a class="nav-link" href="/es/">ES</a>
      <a class="btn-primary" href="/contact/">Get a free quote</a>
    </nav>
  </div>
</header>

<main class="section container-xl space-y-14">
  <section id="lawn">
    <h1 class="font-display text-3xl font-semibold mb-3">Lawn mowing</h1>
    <p class="muted mb-4">Weekly/biweekly mowing, edging, and blow-off. Seasonal plan options.</p>
    <ul class="list-disc pl-5 muted">
      <li>Includes trimming around edges and obstacles.</li>
      <li>Bagging available on request.</li>
    </ul>
  </section>

  <section id="cleanup">
    <h2 class="font-display text-2xl font-semibold mb-3">Clean-ups</h2>
    <p class="muted mb-4">Spring/fall clean-ups, leaf removal, storm debris haul-away.</p>
  </section>

  <section id="mulch">
    <h2 class="font-display text-2xl font-semibold mb-3">Mulch</h2>
    <p class="muted mb-4">Bed prep, landscape fabric, and premium mulch colors.</p>
  </section>

  <section id="hedge">
    <h2 class="font-display text-2xl font-semibold mb-3">Hedge trimming</h2>
    <p class="muted mb-4">Clean lines, shaping, and debris haul-away included.</p>
  </section>

  <div class="mt-6">
    <a class="btn-primary" href="/contact/">Request a quote</a>
  </div>
</main>

<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Contact (EN) with Netlify Forms
# -------------------------------
cat > public/contact/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  $(make_head)
</head>
<body>
$NAV

<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Request a free quote</h1>
  <form name="quote" method="POST" action="/thanks/" data-netlify="true" data-netlify-recaptcha="true" netlify-honeypot="bot-field" class="grid md:grid-cols-2 gap-6">
    <input type="hidden" name="form-name" value="quote" />
    <p class="hidden">
      <label>Don’t fill this out if you're human: <input name="bot-field" /></label>
    </p>

    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Full name</label>
      <input class="w-full border rounded-md p-3" type="text" name="name" placeholder="Full name" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Phone</label>
      <input class="w-full border rounded-md p-3" type="tel" name="phone" placeholder="Phone" required />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Service address</label>
      <input class="w-full border rounded-md p-3" type="text" name="address" placeholder="Address" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Service</label>
      <select class="w-full border rounded-md p-3" name="service" required>
        <option value="">Select a service</option>
        <option>Lawn mowing</option>
        <option>Clean-up</option>
        <option>Mulch</option>
        <option>Hedge trimming</option>
      </select>
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Email (optional)</label>
      <input class="w-full border rounded-md p-3" type="email" name="email" placeholder="you@email.com" />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Details</label>
      <textarea class="w-full border rounded-md p-3" name="details" rows="5" placeholder="Tell us what you need"></textarea>
    </div>
    <div class="md:col-span-2">
      <div data-netlify-recaptcha="true"></div>
    </div>
    <div class="md:col-span-2">
      <button class="btn-primary" type="submit">Request quote</button>
    </div>
  </form>

  <div class="mt-10 muted">
    Prefer phone? <a class="nav-link" href="tel:$PHONE">$PHONE</a> · Email <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a>
  </div>
</main>

$FOOTER
</body>
</html>
EOF

# -------------------------------
# About (EN)
# -------------------------------
cat > public/about/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  $(make_head)
</head>
<body>
$NAV
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">About $BUSINESS_NAME</h1>
  <p class="muted max-w-3xl">We deliver premium landscaping in $CITY with a focus on reliability, clean finishes, and clear communication. Licensed and insured. Same-week availability in peak season.</p>
  <div class="grid md:grid-cols-2 gap-8 mt-10">
    <div class="card">
      <h2 class="font-display text-xl mb-2">Our promise</h2>
      <p class="muted">On-time arrival, careful work, and a spotless clean-up. If something’s not right, we make it right.</p>
    </div>
    <div class="card">
      <h2 class="font-display text-xl mb-2">Service area</h2>
      <p class="muted">$CITY, South Jersey, and surrounding suburbs.</p>
    </div>
  </div>
</main>
$FOOTER
</body>
</html>
EOF

# -------------------------------
# Gallery (stub)
# -------------------------------
cat > public/gallery/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Gallery | Gringo787 Landscaping</title>
  <meta name="description" content="Before and after landscaping projects." />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Project gallery</h1>
  <p class="muted">Add photos to <code>public/assets/gallery</code> and reference them here.</p>
</main>
<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Home
# -------------------------------
cat > public/es/index.html <<EOF
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>$BUSINESS_NAME | Jardinería profesional en $CITY</title>
  <meta name="description" content="Césped, limpiezas y mantenimiento estacional en $CITY. Licenciados, asegurados y puntuales." />
  <link rel="canonical" href="$DOMAIN/es/" />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="$BUSINESS_NAME" />
  <meta property="og:description" content="Jardinería premium en $CITY—reserve servicio para esta semana." />
  <meta property="og:url" content="$DOMAIN/es/" />
  <meta property="og:image" content="$DOMAIN/og-cover.jpg" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
    <nav class="hidden md:flex items-center gap-6">
      <a class="nav-link" href="/es/servicios/">Servicios</a>
      <a class="nav-link" href="/es/contacto/">Contacto</a>
      <a class="nav-link" href="/">EN</a>
      <a class="btn-primary" href="/es/contacto/">Pedir cotización</a>
    </nav>
  </div>
</header>

<section class="section">
  <div class="container-xl grid md:grid-cols-2 gap-10 items-center">
    <div>
      <h1 class="font-display text-4xl md:text-5xl font-semibold">Jardinería premium en $CITY — servicio en la misma semana</h1>
      <p class="mt-4 text-lg muted">Césped, limpiezas y mantenimiento estacional. Licenciados, asegurados y puntuales. Se habla español.</p>
      <div class="mt-6 flex gap-4">
        <a href="/es/contacto/" class="btn-primary">Pedir cotización</a>
        <a href="/es/servicios/" class="btn-secondary">Ver servicios</a>
      </div>
    </div>
    <div>
      <img src="/assets/hero.webp" alt="Césped recién mantenido" class="w-full rounded-xl shadow-soft" loading="eager" />
    </div>
  </div>
</section>

<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© $BUSINESS_NAME</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Services
# -------------------------------
cat > public/es/servicios/index.html <<'EOF'
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Servicios | Gringo787 Landscaping</title>
  <meta name="description" content="Corte de césped, limpiezas, mulch y poda." />
  <link rel="icon" href="/assets/icons/favicon.svg" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>
<main class="section container-xl space-y-14">
  <section id="lawn">
    <h1 class="font-display text-3xl font-semibold mb-3">Corte de césped</h1>
    <p class="muted mb-4">Semanal o quincenal, bordes y limpieza final.</p>
  </section>
  <section id="cleanup">
    <h2 class="font-display text-2xl font-semibold mb-3">Limpiezas</h2>
    <p class="muted mb-4">Primavera/otoño, hojas y escombros.</p>
  </section>
  <section id="mulch">
    <h2 class="font-display text-2xl font-semibold mb-3">Mulch</h2>
    <p class="muted mb-4">Preparación de camas y mulch premium.</p>
  </section>
  <section id="hedge">
    <h2 class="font-display text-2xl font-semibold mb-3">Poda</h2>
    <p class="muted mb-4">Líneas limpias y formado correcto.</p>
  </section>
  <div class="mt-6">
    <a class="btn-primary" href="/es/contacto/">Pedir cotización</a>
  </div>
</main>
<footer class="mt-20 border-t">
  <div class="container-xl py-10 text-sm muted">© Gringo787 Landscaping</div>
</footer>
</body>
</html>
EOF

# -------------------------------
# Spanish Contact
# -------------------------------
cat > public/es/contacto/index.html <<EOF
<!doctype html>
<html lang="es">
<head>
  $(make_head)
</head>
<body>
<header class="border-b">
  <div class="container-xl py-4 flex items-center justify-between">
    <a href="/es/" class="flex items-center gap-2">
      <img src="/assets/icons/favicon.svg" alt="Logo" class="w-8 h-8" />
      <span class="font-display font-semibold">Gringo787</span>
    </a>
  </div>
</header>

<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-6">Solicitar cotización</h1>
  <form name="cotizacion" method="POST" action="/thanks/" data-netlify="true" data-netlify-recaptcha="true" netlify-honeypot="campo-bot" class="grid md:grid-cols-2 gap-6">
    <input type="hidden" name="form-name" value="cotizacion" />
    <p class="hidden">
      <label>No completar si eres humano: <input name="campo-bot" /></label>
    </p>

    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Nombre completo</label>
      <input class="w-full border rounded-md p-3" type="text" name="nombre" placeholder="Nombre completo" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Teléfono</label>
      <input class="w-full border rounded-md p-3" type="tel" name="telefono" placeholder="Teléfono" required />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Dirección de servicio</label>
      <input class="w-full border rounded-md p-3" type="text" name="direccion" placeholder="Dirección" required />
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Servicio</label>
      <select class="w-full border rounded-md p-3" name="servicio" required>
        <option value="">Seleccionar</option>
        <option>Corte de césped</option>
        <option>Limpieza</option>
        <option>Mulch</option>
        <option>Poda</option>
      </select>
    </div>
    <div class="md:col-span-1">
      <label class="block text-sm font-medium mb-1">Correo (opcional)</label>
      <input class="w-full border rounded-md p-3" type="email" name="correo" placeholder="tu@email.com" />
    </div>
    <div class="md:col-span-2">
      <label class="block text-sm font-medium mb-1">Detalles</label>
      <textarea class="w-full border rounded-md p-3" name="detalles" rows="5" placeholder="Cuéntanos"></textarea>
    </div>
    <div class="md:col-span-2">
      <div data-netlify-recaptcha="true"></div>
    </div>
    <div class="md:col-span-2">
      <button class="btn-primary" type="submit">Enviar</button>
    </div>
  </form>

  <div class="mt-10 muted">
    También por teléfono <a class="nav-link" href="tel:$PHONE">$PHONE</a> · Email <a class="nav-link" href="mailto:$EMAIL">$EMAIL</a>
  </div>
</main>

<footer class="mt-20 border-t"><div class="container-xl py-10 text-sm muted">© $BUSINESS_NAME</div></footer>
</body>
</html>
EOF

# -------------------------------
# Thanks and 404
# -------------------------------
cat > public/thanks/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Thanks | Gringo787 Landscaping</title>
  <meta name="robots" content="noindex" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">Thanks for reaching out!</h1>
  <p class="muted">We received your request and will get back to you soon.</p>
  <a href="/" class="btn-primary mt-6 inline-flex">Back to home</a>
</main>
</body>
</html>
EOF

cat > public/404.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Not found | Gringo787 Landscaping</title>
  <meta name="robots" content="noindex" />
  <link href="/styles.css" rel="stylesheet" />
</head>
<body>
<main class="section container-xl">
  <h1 class="font-display text-3xl font-semibold mb-4">Page not found</h1>
  <p class="muted">The page you're looking for doesn’t exist.</p>
  <a href="/" class="btn-primary mt-6 inline-flex">Go home</a>
</main>
</body>
</html>
EOF

# -------------------------------
# Robots (initial) — will be kept up to date by CI
# -------------------------------
cat > public/robots.txt <<EOF
User-agent: *
Allow: /
Sitemap: $DOMAIN/sitemap.xml
EOF

# Touch sitemap (CI will regenerate)
echo "<!-- generated by CI -->" > public/sitemap.xml

echo "Upgrade bundle created. Next steps:
1) npm ci
2) npm run build
3) Review public/ and commit."
