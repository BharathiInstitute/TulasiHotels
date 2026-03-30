# Tulasi Hotels — Marketing Website Implementation Plan

**Document Version:** 1.0  
**Date:** June 2025  
**App Version:** 9.1.0+43  
**Status:** Planning Phase  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Audit](#2-current-state-audit)
3. [Brand Identity & Design System](#3-brand-identity--design-system)
4. [Information Architecture](#4-information-architecture)
5. [Page-by-Page Specification](#5-page-by-page-specification)
6. [Content Strategy](#6-content-strategy)
7. [SEO Strategy](#7-seo-strategy)
8. [Performance & Core Web Vitals](#8-performance--core-web-vitals)
9. [Conversion Rate Optimization (CRO)](#9-conversion-rate-optimization-cro)
10. [Analytics & KPI Framework](#10-analytics--kpi-framework)
11. [Technical Architecture](#11-technical-architecture)
12. [Responsive Design Breakpoints](#12-responsive-design-breakpoints)
13. [Accessibility (WCAG 2.1 AA)](#13-accessibility-wcag-21-aa)
14. [Deployment & Hosting](#14-deployment--hosting)
15. [Implementation Phases & Milestones](#15-implementation-phases--milestones)

---

## 1. Executive Summary

### Objective
Build a professional, conversion-optimized HTML/CSS marketing website for **Tulasi Hotels** — a comprehensive hotel and restaurant management SaaS application targeting hotel owners, restaurant operators, and hospitality businesses across India.

### Scope
- Complete **rewrite** of the existing retail-branded website (`website/` directory)
- 10 pages: Home, Features, Screenshots, Pricing, About, Support, Download, Privacy Policy, Terms, Blog (landing)
- Pure HTML5 + CSS3 + vanilla JS (no frameworks) for maximum performance
- Mobile-first responsive design
- SEO-optimized for Indian hospitality market
- Conversion-focused with clear CTA funnels

### Key Differentiator
Tulasi Hotels is an **all-in-one hotel management platform** with 22+ integrated modules — POS billing, kitchen display, table management, staff management, inventory, reservations, customer feedback, compliance, and 9 analytics dashboards — all accessible via web, Android, and Windows with offline-first capability.

### Target Audience
| Segment | Description | Pain Points |
|---------|-------------|-------------|
| **Small Hotels (10-50 rooms)** | Budget hotels, lodges, dharamshalas | Manual registers, no analytics, compliance tracking |
| **Restaurants & Dhabas** | Standalone restaurants, QSR, cafes | Slow billing, no kitchen display, food wastage |
| **Banquet & Event Venues** | Marriage halls, party venues | Reservation chaos, no event management |
| **Restaurant Chains** | 2-10 outlet chains | Inconsistent operations, no comparative reports |

---

## 2. Current State Audit

### Existing Website Problems
| Issue | Impact | Priority |
|-------|--------|----------|
| Branded as "TULASI STORES" (retail) | Complete brand mismatch with hotel app | 🔴 Critical |
| Content about retail features (barcode, kirana) | Misleads hotel industry visitors | 🔴 Critical |
| Links point to `stores.tulasierp.com` | Wrong app URL | 🔴 Critical |
| No hotel-specific imagery or messaging | Zero resonance with target audience | 🔴 Critical |
| About page references "12M small retailers" | Wrong market positioning | 🟡 High |
| Pricing page has retail-tier features | Needs hotel-specific plan features | 🟡 High |
| Missing structured data for SaaS | Poor rich snippet potential | 🟡 High |

### Existing Assets to Retain
- **Design system foundation:** CSS variables, color tokens, typography scale (Inter font family)
- **Component library:** Navbar, buttons, cards, pricing grid, feature blocks, footer — all reusable
- **File structure:** `website/index.html`, `website/src/pages/`, `website/src/css/`, `website/assets/`
- **Infrastructure:** Firebase Hosting, `sitemap.xml`, `robots.txt`
- **Theme color:** `#10B981` (emerald green) — consistent with Flutter app

### Existing CSS Design Tokens (Retain)
```css
--color-primary: #10B981;
--color-primary-dark: #059669;
--color-primary-light: #34D399;
--color-primary-50: #ECFDF5;
--color-accent: #0D9488;
--font-heading: 'Inter', system-ui, sans-serif;
--font-body: 'Inter', system-ui, sans-serif;
--container-max: 1200px;
--radius-xl: 1.5rem;
```

---

## 3. Brand Identity & Design System

### Brand Voice
- **Tone:** Professional yet approachable, confident, modern Indian
- **Language:** English with Hindi-familiar phrases ("Khata," "Udhar," "Dukandaar" where appropriate)
- **Tagline Options:**
  1. "India's Smartest Hotel Management Platform"
  2. "Run Your Hotel Like a Pro — From One App"
  3. "All-in-One Hotel & Restaurant Management"

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#10B981` | CTAs, links, active states, brand moments |
| Primary Dark | `#059669` | Hover states, gradients |
| Primary Light | `#34D399` | Backgrounds, badges |
| Primary 50 | `#ECFDF5` | Light backgrounds, cards |
| Accent | `#0D9488` | Secondary actions, teal accents |
| Surface | `#FFFFFF` | Page background |
| Surface Alt | `#F9FAFB` | Alternating sections |
| Dark BG | `#0F172A` | Footer, dark sections |
| Text Primary | `#1F2937` | Headings, body |
| Text Secondary | `#6B7280` | Captions, descriptions |
| Error | `#EF4444` | Alerts, validation |
| Warning | `#F59E0B` | License expiry, warnings |
| Success | `#10B981` | Confirmations |

### Typography Scale
```
Display:  clamp(2.25rem, 5vw, 3.75rem) / 800 weight — Hero headings
H2:       clamp(1.75rem, 4vw, 2.75rem) / 700 weight — Section titles
H3:       clamp(1.25rem, 3vw, 1.75rem) / 700 weight — Card titles
H4:       1.25rem / 600 weight — Subheadings
Body:     1rem / 400 weight — Default text
Body LG:  1.125rem / 400 weight — Section descriptions
Small:    0.875rem / 400 weight — Captions, metadata
XSmall:   0.75rem / 600 weight — Badges, labels
```

### Iconography
- **System:** Inline SVG icons (no icon font for performance)
- **Style:** Outlined, 24px base, 1.5px stroke
- **Feature icons:** Emoji-based (existing pattern) or custom SVG set
- **Illustrations:** CSS-rendered UI mockups (existing pattern — no image dependencies)

### Spacing System
```
4px  — xs (icon padding, tight gaps)
8px  — sm (inline spacing)
16px — md (card padding, section inner)
24px — lg (component gaps)
32px — xl (section gaps)
48px — 2xl (between sections)
80px — section padding (var(--section-padding))
```

---

## 4. Information Architecture

### Sitemap

```
tulasierp.com/ (or hotels.tulasierp.com/)
├── index.html                    — Homepage (hero, value prop, feature overview, social proof, CTA)
├── src/pages/
│   ├── features.html             — All 22 feature modules detailed
│   ├── screenshots.html          — App screenshots & interactive tour
│   ├── pricing.html              — Plans, comparison table, FAQ
│   ├── about.html                — Company story, mission, team
│   ├── support.html              — Help center, contact, FAQ
│   ├── download.html             — Download links (Android APK, Web App, Windows)
│   ├── privacy.html              — Privacy policy
│   ├── terms.html                — Terms of service (NEW)
│   └── blog.html                 — Blog landing (NEW, static initially)
├── src/css/
│   └── styles.css                — Design system + all component styles
├── src/js/
│   └── main.js                   — Interactions (navbar, animations, pricing toggle)
├── assets/
│   └── images/                   — App icon, screenshots, illustrations
├── robots.txt
├── sitemap.xml
└── favicon.png
```

### Navigation Structure

**Primary Nav (Desktop):**
```
[Logo] Tulasi Hotels    Home | Features | Screenshots | Pricing | About | Support    [Open App] [Download ▼]
```

**Primary Nav (Mobile):**
```
[Logo] Tulasi Hotels                                                                  [☰ Hamburger]
```
Hamburger expands: Home, Features, Screenshots, Pricing, About, Support, Download, Open App

**Footer:**
```
┌──────────────────────────────────────────────────────────────────────────┐
│  [Logo] Tulasi Hotels                                                    │
│  India's Smartest Hotel Management Platform                              │
│                                                                          │
│  Product          Company         Support           Legal                │
│  Features         About           Help Center       Privacy Policy       │
│  Screenshots      Blog            Contact Us        Terms of Service     │
│  Pricing          Careers         FAQ               Refund Policy        │
│  Download                         WhatsApp                               │
│                                                                          │
│  [Play Store] [Web App] [Windows]                                        │
│                                                                          │
│  © 2025 Tulasi Hotels. All rights reserved.                              │
│  Made with ♥ in India                                                    │
└──────────────────────────────────────────────────────────────────────────┘
```

### User Journey Funnels

**Funnel 1 — New Visitor (Search/Ad)**
```
Landing Page → Features → Pricing → [Open App / Download] → Registration
```

**Funnel 2 — Referral Visitor**
```
Homepage → Screenshots → [Open App] → Registration
```

**Funnel 3 — Support Seeker**
```
Homepage → Support → FAQ / Contact → [Open App]
```

**Funnel 4 — Comparison Shopper**
```
Features → Pricing (comparison table) → [Start Free Trial]
```

---

## 5. Page-by-Page Specification

### 5.1 Homepage (`index.html`)

**Purpose:** First impression, value proposition, conversion entry point  
**Target:** < 3s load, > 40% scroll depth, > 5% CTA click rate

#### Sections (Top to Bottom):

| # | Section | Content | CTA |
|---|---------|---------|-----|
| 1 | **Navbar** | Logo, nav links, "Open App" ghost btn, "Download Now" primary btn | Open App, Download |
| 2 | **Hero** | H1: "India's Smartest Hotel Management Platform" / Sub: "Billing, Kitchen Display, Staff, Inventory, Reservations, Reports — all in one app. Works offline." / CSS mockup of dashboard | "Start Free" (primary), "Watch Demo" (ghost) |
| 3 | **Trust Bar** | "Trusted by 500+ hotels across India" + logos/badges (if available) | — |
| 4 | **Problem → Solution** | 3 cards: "Paper registers → Digital billing" / "Scattered tools → One dashboard" / "No insights → 9 analytics reports" | — |
| 5 | **Feature Overview Grid** | 6 key feature cards with icons: POS Billing, Kitchen Display, Table Management, Staff & HR, Inventory, Reports & Analytics | "See All Features →" |
| 6 | **Customer Portal Showcase** | Show public URLs: QR Menu, Online Ordering, Reservations, Feedback — "Your customers can order and book without downloading any app" | "Try Customer Menu →" |
| 7 | **Video Demo** | Embedded YouTube/Loom walkthrough (placeholder initially) | "Watch Full Demo" |
| 8 | **Testimonials / Social Proof** | 3 customer quote cards (collect from users) | — |
| 9 | **Pricing Teaser** | "Start free, upgrade when you grow" + 3 plan cards (brief) | "View Full Pricing →" |
| 10 | **Platform Availability** | "Available on Android, Web & Windows" + device icons | Download links per platform |
| 11 | **Final CTA** | "Ready to modernize your hotel?" + email capture or "Start Free" | "Start Free Trial" |
| 12 | **Footer** | Full footer with nav, social, legal links | — |

#### Hero CSS Mockup Specification
Instead of screenshot images (which are harder to maintain), build a CSS-rendered dashboard mockup showing:
- Sidebar with navigation items
- Dashboard with today's revenue (₹47,250), orders (34), occupancy (78%)
- Mini chart showing weekly trend
- Active table grid (4 tables with status colors)

---

### 5.2 Features Page (`features.html`)

**Purpose:** Comprehensive feature showcase, SEO hub for feature keywords  
**Target:** > 60% scroll depth, > 3% "Open App" click rate

#### Feature Groups (22 Modules)

Organize into 7 thematic sections with alternating left/right layouts:

**Section 1 — Billing & Orders**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| POS Billing | Lightning-Fast Hotel Billing | Menu-based billing, multiple payment modes (Cash/UPI/Card/Credit), GST auto-calculation, PDF receipts, bill history | Billing screen with food items |
| Orders | Smart Order Management | Table-wise orders, item modifications, kitchen routing, split billing, order status tracking | Order queue view |
| Kitchen Display (KDS) | Real-Time Kitchen Display | Live order feed for kitchen staff, item preparation tracking, priority ordering, timer management | KDS cards |
| GST Export | One-Click GST Reports | Auto GST calculation, export-ready reports, GSTR-1 compatible data | Export button + table |

**Section 2 — Table & Reservation Management**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Tables | Visual Table Management | Floor plan layout editor, real-time status (Available/Occupied/Reserved/Dirty), seat capacity tracking | Table grid layout |
| Reservations | Advance Table Reservations | Calendar view, guest info capture, special requests, no-show tracking, customer-facing booking URL | Reservation calendar |

**Section 3 — Menu & Products**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Products | Complete Menu Management | Menu items with images, pricing, categories, availability toggle, combo meals, daily specials | Menu grid |
| Combos | Combo & Meal Deals | Build combo meals, auto pricing, time-based specials | Combo builder card |
| Daily Specials | Daily Specials Board | Schedule rotating specials, feature items by day | Specials board |

**Section 4 — Staff & HR**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Staff Management | Complete Staff Directory | Profiles, roles, contact info, role-based access control, permission manager | Staff list |
| Attendance | Biometric-Free Attendance | Digital check-in/out, shift-wise tracking, personal attendance view, detailed reports | Attendance calendar |
| Shift Scheduling | Drag-and-Drop Shifts | Shift matrix, schedule drafts, conflict detection | Shift grid |
| Tasks | Staff Task Board | Kanban-style task assignment, deadlines, progress tracking | Task board |
| Salary | Salary & Payroll | Attendance-based calculation, advance tracking, salary history | Salary summary |
| Cash Register | Cash Register Management | Drawer tracking, shift handover, discrepancy alerts | Cash register card |
| Messages | Internal Messaging | Staff-to-staff messaging, announcements, read receipts | Message thread |

**Section 5 — Inventory & Procurement**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Ingredients | Ingredient Inventory | Stock levels, low-stock alerts, unit tracking (Kg/L/Pcs), purchase history | Inventory list |
| Vendors | Vendor Management | Supplier directory, contact info, purchase orders | Vendor cards |
| Wastage | Food Wastage Tracking | Log daily waste, category-wise tracking, waste reduction insights | Wastage form |

**Section 6 — Customer Engagement**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Customer Portal | QR Code Customer Portal | Public URLs for menu, ordering, feedback, reservations — no app download needed | Phone mockup with QR |
| Coupons | Discount & Coupon Engine | Create codes, set validity, usage limits, auto-apply at billing | Coupon card |
| Feedback | Customer Feedback & NPS | Public feedback URL, star ratings, NPS surveys, feedback dashboard + analytics | Feedback form → Dashboard |

**Section 7 — Compliance & Events**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Licenses | License & Certification Tracking | Expiry alerts, renewal reminders, document storage | License timeline |
| Equipment | Equipment Maintenance | Maintenance schedules, service history, AMC tracking | Equipment list |
| Complaints | Complaint Management | Log, track, resolve complaints, status pipeline | Complaint board |
| Events | Event & Banquet Management | Create events, manage bookings, track banquet details | Event cards |

**Section 8 — Analytics & Reports**
| Module | Headline | Key Points | CSS Mockup |
|--------|----------|------------|------------|
| Dashboard | Real-Time Analytics Dashboard | Today's revenue, orders, covers, occupancy, trend charts | Dashboard mockup |
| 9 Reports | Deep Analytics Suite | Menu Performance, Weekly Summary, P&L, Peak Hours, Item Sales, Comparative Period, Feedback Report, Advanced Reports, Custom Date | Report grid |

#### Feature Page Bottom CTA
"22+ modules. One subscription. Get started free." → [Start Free Trial]

---

### 5.3 Screenshots Page (`screenshots.html`)

**Purpose:** Visual proof, build confidence, reduce friction  
**Target:** > 2 min time-on-page

#### Layout
- Category tabs: All | Billing | Kitchen | Tables | Staff | Reports | Customer
- Masonry/grid gallery of app screenshots
- Click to enlarge (lightbox)
- Each screenshot has a caption describing the feature

#### Screenshots Needed (Priority Order)
1. Dashboard with analytics
2. POS Billing screen with food items
3. Kitchen Display with order cards
4. Table layout with status colors
5. Staff attendance calendar
6. Reservation calendar
7. Customer menu (mobile view of `/menu/:hotelId`)
8. Feedback dashboard with NPS chart
9. P&L Report
10. Settings page
11. Order detail with split bill
12. Ingredient inventory list

---

### 5.4 Pricing Page (`pricing.html`)

**Purpose:** Convert interest into action, reduce price anxiety  
**Target:** > 15% CTA click rate, < 50% bounce rate

#### Pricing Structure

| | Free | Pro | Enterprise |
|--|------|-----|-----------|
| **Price** | ₹0/mo | ₹999/mo (₹799/mo annual) | Custom |
| **Staff** | 2 | 10 | Unlimited |
| **Products** | 50 | Unlimited | Unlimited |
| **Tables** | 5 | Unlimited | Unlimited |
| **Reports** | Basic Dashboard | All 9 Reports | All + Custom |
| **Customer Portal** | Menu only | Full (Order, Reserve, Feedback) | Full + White-label |
| **Modules** | Billing, Products, Orders | All 22 modules | All + API access |
| **Support** | Community | Priority Email + WhatsApp | Dedicated Account Manager |
| **Data** | Cloud sync | Cloud sync + Export | Cloud + On-premise option |

#### Pricing Page Sections
1. **Hero:** "Simple, Transparent Pricing" / "Start free. Upgrade when you grow."
2. **Billing Toggle:** Monthly ↔ Annual (Save 20%)
3. **Pricing Cards:** 3-column grid (Free / Pro / Enterprise)
4. **Feature Comparison Table:** Detailed row-by-row comparison (expandable on mobile)
5. **FAQ Section:** 8-10 common pricing questions
6. **Money-Back Guarantee Badge:** "7-day money-back guarantee"
7. **CTA:** "Start your free trial — no credit card required"

#### Pricing FAQ (Content)
- Is there a free plan? → Yes, forever free with core features.
- Can I switch plans? → Upgrade or downgrade anytime.
- What payment methods? → UPI, credit/debit card, net banking.
- Is there a contract? → No contracts. Cancel anytime.
- Do I need to pay for each device? → No, one subscription works on all devices.
- Is my data safe? → Encrypted on Firebase with automatic backups.
- Can I export my data? → Yes, CSV/PDF export on all paid plans.
- What happens if I stop paying? → Downgrade to Free plan. No data lost.

---

### 5.5 About Page (`about.html`)

**Purpose:** Build trust, tell human story, establish credibility  

#### Sections
1. **Hero:** "Built for India's Hospitality Industry"
2. **Mission Statement:** "We believe every hotel and restaurant deserves enterprise-grade technology at an affordable price."
3. **The Problem We Solve:** 3 problem→solution cards:
   - "Paper registers & manual billing → Instant digital billing with GST"
   - "Scattered WhatsApp groups for staff → One integrated staff management platform"
   - "No visibility into business health → 9 real-time analytics dashboards"
4. **By The Numbers:** Animated counters — Hotels served, Orders processed, Cities active, Uptime %
5. **Our Values:** 4 value cards — Simplicity, Reliability (Offline-first), Affordability, Indian-first
6. **Technology Stack:** Brief mention of Flutter, Firebase, cross-platform
7. **Contact CTA:** Office address, email, WhatsApp

---

### 5.6 Support Page (`support.html`)

**Purpose:** Reduce support tickets, enable self-service  

#### Sections
1. **Hero:** "We're Here to Help"
2. **Quick Help Cards:** 3 cards:
   - 📖 "Getting Started Guide" → setup walkthrough
   - 💬 "WhatsApp Support" → direct chat link
   - 📧 "Email Support" → support email form
3. **FAQ Accordion:** 15-20 categorized questions:
   - **Getting Started** (5 questions)
   - **Billing & Payments** (4 questions)
   - **Features** (4 questions)
   - **Technical** (4 questions)
4. **Still Need Help?** Contact form (Name, Email, Hotel Name, Message)
5. **Business Hours:** Support availability (IST times)

---

### 5.7 Download Page (`download.html`)

**Purpose:** Platform-specific download conversion  

#### Sections
1. **Hero:** "Download Tulasi Hotels"
2. **Platform Cards:**
   - **Android:** "Download from Play Store" + direct APK download
   - **Web App:** "Open in Browser — No installation needed" → app URL
   - **Windows:** "Download for Windows 10/11" → installer download
3. **System Requirements:** Simple table per platform
4. **QR Code:** Scan to download on mobile
5. **Installation Guide:** Brief 3-step guide per platform

---

### 5.8 Privacy Policy (`privacy.html`)

Standard SaaS privacy policy covering:
- Data collection (name, email, hotel info, billing data)
- Firebase storage & encryption
- Third-party services (Google Analytics, Firebase, payment processor)
- Data retention policy
- User rights (access, correction, deletion)
- Cookie policy
- Contact for privacy concerns

---

### 5.9 Terms of Service (`terms.html`) — NEW

Standard SaaS terms covering:
- Service description
- Account responsibilities
- Acceptable use policy
- Payment terms
- Intellectual property
- Data ownership (user owns their data)
- Service availability (no SLA guarantee for free tier)
- Termination
- Limitation of liability
- Governing law (Indian jurisdiction)

---

### 5.10 Blog Landing (`blog.html`) — NEW

**Purpose:** SEO content hub, thought leadership  

Minimal initial implementation:
- Hero: "Tulasi Hotels Blog — Tips for Hotel & Restaurant Owners"
- 3-4 placeholder article cards with titles like:
  - "5 Ways to Reduce Food Wastage in Your Restaurant"
  - "How Digital Billing Can Save Your Hotel 2 Hours Daily"
  - "FSSAI Compliance Checklist for Small Hotels"
  - "Why Every Restaurant Needs a Kitchen Display System"
- "Coming Soon" state — builds SEO intent now, content added later

---

## 6. Content Strategy

### Messaging Framework

**Primary Message:** "One app to manage your entire hotel — billing, kitchen, staff, inventory, reservations, and analytics."

**Supporting Messages:**
1. **Speed:** "Create bills in seconds, not minutes"
2. **Offline:** "Works even without internet — sync when you're back online"
3. **All-in-one:** "Replace 5+ tools with one platform"
4. **Customer-facing:** "Your guests order, book, and review — without downloading an app"
5. **Affordable:** "Start free, upgrade when you grow"
6. **Indian:** "Built specifically for Indian hotels and restaurants"

### Content Tone Guidelines
- Use "you" and "your hotel" — speak directly to the owner
- Avoid jargon: say "billing" not "point-of-sale system"
- Use Indian currency (₹) and Indian examples
- Reference real hotel operations: "morning rush," "banquet season," "FSSAI inspection"
- Keep paragraphs short (2-3 sentences max)
- Use numbers: "22 modules," "9 reports," "3 platforms"

### Social Proof Strategy
- Collect 5-10 testimonials from existing users (with name, hotel name, city)
- "Join 500+ hotels across India" (update number periodically)
- Star rating badge if available on Play Store
- "Featured on" media logos (if applicable)

---

## 7. SEO Strategy

### Target Keywords

**Primary (High Intent):**
| Keyword | Monthly Searches (est.) | Difficulty | Target Page |
|---------|------------------------|------------|-------------|
| hotel management software | 8,100 | Medium | Homepage |
| restaurant billing app | 4,400 | Medium | Homepage |
| hotel billing software India | 2,400 | Low | Features |
| restaurant POS app | 3,600 | Medium | Features |
| hotel management app | 5,400 | Medium | Homepage |

**Secondary (Feature-specific):**
| Keyword | Target Page |
|---------|-------------|
| kitchen display system for restaurant | Features (KDS section) |
| restaurant table management software | Features (Tables section) |
| hotel staff attendance app | Features (Staff section) |
| restaurant inventory management | Features (Inventory section) |
| food wastage tracking app | Features (Wastage section) |
| hotel reservation system online | Features (Reservations section) |
| restaurant analytics dashboard | Features (Reports section) |
| QR code menu for restaurant | Features (Customer Portal section) |
| GST billing software for hotel | Features (Billing section) |

**Long-tail (Blog/FAQ):**
- "best hotel management software for small hotels in India"
- "how to track food wastage in restaurant"
- "free restaurant billing app with GST"
- "hotel staff management software free"
- "restaurant kitchen order management system"

### On-Page SEO Checklist (Per Page)
- [ ] Unique `<title>` tag (50-60 chars) with primary keyword
- [ ] Unique `<meta description>` (150-160 chars) with CTA
- [ ] Single `<h1>` with primary keyword
- [ ] Hierarchical heading structure (H1 → H2 → H3)
- [ ] Alt text on all images (descriptive + keyword-rich)
- [ ] Internal links to other pages (3-5 per page)
- [ ] External links where relevant (FSSAI, GST portal)
- [ ] Schema.org structured data:
  - `SoftwareApplication` on Homepage
  - `FAQPage` on Support/Pricing
  - `Organization` in footer (all pages)
  - `BreadcrumbList` on all subpages
  - `Product` with `Offer` on Pricing

### Technical SEO
- [ ] `robots.txt` — allow all, sitemap reference
- [ ] `sitemap.xml` — all 10 pages with `lastmod` dates
- [ ] Canonical URLs on all pages
- [ ] Open Graph tags (og:title, og:description, og:image, og:type)
- [ ] Twitter Card tags (twitter:card, twitter:title, twitter:description)
- [ ] `hreflang="en-IN"` for India-specific content
- [ ] 301 redirect from old retail URLs if any are indexed

### Structured Data (JSON-LD)

**Homepage — SoftwareApplication:**
```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Tulasi Hotels",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Android, Web, Windows",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "INR"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "ratingCount": "150"
  }
}
```

---

## 8. Performance & Core Web Vitals

### Target Metrics (Google Core Web Vitals)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | Hero section render |
| **FID** (First Input Delay) | < 100ms | First interaction (navbar click) |
| **CLS** (Cumulative Layout Shift) | < 0.1 | No layout shifts during load |
| **FCP** (First Contentful Paint) | < 1.8s | Navbar + hero text |
| **TTFB** (Time to First Byte) | < 600ms | Firebase Hosting CDN |
| **TTI** (Time to Interactive) | < 3.5s | Full page interactive |

### Performance Optimization Strategies

**CSS:**
- [ ] Single CSS file, minified (< 25KB gzipped target)
- [ ] Critical CSS inlined in `<head>` for above-fold content
- [ ] CSS custom properties for theming (no preprocessor needed)
- [ ] No unused CSS — each page gets what it needs via shared CSS
- [ ] `font-display: swap` for web fonts

**JavaScript:**
- [ ] Minimal JS — only for: navbar toggle, scroll animations, pricing toggle, FAQ accordion
- [ ] Single JS file, minified (< 10KB gzipped target)
- [ ] Deferred loading (`defer` attribute)
- [ ] IntersectionObserver for scroll animations (no scroll event listeners)
- [ ] No jQuery, no libraries

**Images:**
- [ ] WebP format with PNG fallback
- [ ] `loading="lazy"` on below-fold images
- [ ] `width` and `height` attributes to prevent CLS
- [ ] App icon: serve multiple sizes (32, 192, 512)
- [ ] Prefer CSS-rendered mockups over screenshot images

**Fonts:**
- [ ] Google Fonts: Inter (preconnect + display=swap)
- [ ] Load only needed weights: 400, 500, 600, 700, 800
- [ ] Fallback: `system-ui, -apple-system, sans-serif`

**Hosting:**
- [ ] Firebase Hosting with global CDN
- [ ] Gzip/Brotli compression (automatic on Firebase)
- [ ] Long-term caching headers for static assets
- [ ] HTTP/2 push for critical resources

---

## 9. Conversion Rate Optimization (CRO)

### CTA Hierarchy

| Priority | CTA | Placement | Style |
|----------|-----|-----------|-------|
| Primary | "Start Free Trial" / "Open App" | Hero, pricing cards, final CTA | Solid green button |
| Secondary | "Download Now" | Navbar, hero, download section | Outlined green button |
| Tertiary | "Watch Demo" | Hero, features | Ghost button with play icon |
| Quaternary | "Contact Sales" | Enterprise pricing, support | Text link |

### Conversion Points (Per Page)

| Page | Primary Conversion | Secondary Conversion |
|------|-------------------|---------------------|
| Homepage | Open App / Start Free | Download App / Watch Demo |
| Features | Open App | View Pricing |
| Screenshots | Open App | Download |
| Pricing | Start Free (Free tier) / Contact Sales (Enterprise) | — |
| About | Open App | — |
| Support | Open App | Submit Contact Form |
| Download | Platform-specific Download | Open Web App |

### CRO Best Practices
- [ ] Single primary CTA per viewport (avoid CTA competition)
- [ ] Sticky navbar with CTA visible at all scroll positions
- [ ] Social proof near CTAs (trust badges, user count)
- [ ] Pricing anchor: show Pro plan as "Most Popular"
- [ ] Free plan prominently displayed to reduce price objection
- [ ] Mobile CTAs: full-width buttons, thumb-friendly (min 48px height)
- [ ] Exit-intent popup (optional, Phase 2): "Start free before you go"

### A/B Test Hypotheses (Phase 2)
1. Hero headline: "India's Smartest Hotel Management Platform" vs "Run Your Hotel From One App"
2. CTA text: "Start Free Trial" vs "Open App Free" vs "Get Started"
3. Pricing page: 3 plans vs 2 plans (remove Enterprise)
4. Social proof: user count vs testimonial in hero

---

## 10. Analytics & KPI Framework

### Tool Stack
| Tool | Purpose | Implementation |
|------|---------|---------------|
| Google Analytics 4 (GA4) | Traffic, behavior, conversions | `gtag.js` in `<head>` |
| Google Search Console | SEO performance, indexing | Verify via DNS/Firebase |
| Microsoft Clarity | Heatmaps, session recordings | Script tag |
| Firebase Analytics | Cross-platform (web + app) | Already integrated |

### KPI Dashboard — Primary Metrics

#### Traffic KPIs
| KPI | Definition | Target (Month 3) | Target (Month 6) |
|-----|-----------|-------------------|-------------------|
| Monthly Unique Visitors | GA4 unique users | 2,000 | 8,000 |
| Organic Traffic % | Non-paid search visits / total | 30% | 50% |
| Bounce Rate | Single-page sessions | < 55% | < 45% |
| Avg. Session Duration | Time on site | > 1:30 | > 2:30 |
| Pages per Session | Avg pages viewed | > 2.0 | > 2.5 |

#### Engagement KPIs
| KPI | Definition | Target |
|-----|-----------|--------|
| Scroll Depth (Homepage) | % users scrolling past 50% | > 40% |
| Feature Page Engagement | Users who view 3+ feature sections | > 30% |
| Video Play Rate | Users who click play on demo video | > 15% |
| FAQ Interaction Rate | Users who expand 1+ FAQ | > 25% |
| Screenshot Gallery Views | Users who view 3+ screenshots | > 20% |

#### Conversion KPIs
| KPI | Definition | Target (Month 3) | Target (Month 6) |
|-----|-----------|-------------------|-------------------|
| CTA Click Rate (Homepage) | Clicks on primary CTA / visitors | 5% | 8% |
| Pricing Page Visit Rate | Homepage → Pricing visitors | 10% | 15% |
| Download Page Visit Rate | Any page → Download visitors | 8% | 12% |
| App Open Rate | "Open App" clicks / total visitors | 3% | 6% |
| Download Conversion Rate | Download clicks / Download page visitors | 25% | 35% |
| Lead Capture Rate | Contact form submissions / Support visitors | 10% | 15% |
| Trial-to-Paid Conversion | Free trial → paid subscription | 5% | 10% |

#### SEO KPIs
| KPI | Definition | Target (Month 3) | Target (Month 6) |
|-----|-----------|-------------------|-------------------|
| Indexed Pages | Pages in Google Search Console | 10/10 | 10/10 + blog posts |
| Avg. Position (Primary KWs) | Google Search Console | < 30 | < 15 |
| Click-Through Rate (SERP) | Clicks / impressions | 3% | 5% |
| Organic Keywords Ranking | Total keywords in top 100 | 50 | 200 |
| Backlinks (Unique Domains) | Referring domains | 5 | 20 |

#### Performance KPIs
| KPI | Definition | Target |
|-----|-----------|--------|
| Lighthouse Performance Score | Google Lighthouse | > 90 |
| Lighthouse SEO Score | Google Lighthouse | > 95 |
| Lighthouse Accessibility Score | Google Lighthouse | > 90 |
| LCP | Largest Contentful Paint | < 2.5s |
| CLS | Cumulative Layout Shift | < 0.1 |
| Page Size (Compressed) | Total transfer size | < 150KB |

### Event Tracking Plan (GA4)

```
| Event Name              | Trigger                       | Parameters                    |
|-------------------------|-------------------------------|-------------------------------|
| page_view               | Each page load                | page_title, page_location     |
| cta_click               | Any CTA button click          | cta_text, cta_location, page  |
| nav_click               | Navbar link click             | link_text, destination        |
| pricing_toggle          | Monthly/Annual switch         | billing_period                |
| faq_expand              | FAQ accordion open            | question_text, page           |
| video_play              | Demo video play               | video_id, page                |
| screenshot_view         | Screenshot lightbox open      | screenshot_name               |
| download_click          | Download button click         | platform (android/web/win)    |
| contact_submit          | Support form submission       | —                             |
| scroll_depth            | 25%, 50%, 75%, 100% scroll   | percent, page                 |
| external_link           | Click to app/play store       | destination_url               |
| feature_section_view    | Feature section enters viewport| feature_name                 |
```

### Reporting Cadence
| Report | Frequency | Audience | Contents |
|--------|-----------|----------|----------|
| Traffic Snapshot | Weekly | Owner | Visitors, bounce rate, top pages |
| Conversion Report | Bi-weekly | Owner/Marketing | CTA clicks, downloads, signups |
| SEO Performance | Monthly | Owner/SEO | Rankings, organic traffic, indexed pages |
| Full Analytics Review | Monthly | All stakeholders | All KPIs, insights, recommendations |

---

## 11. Technical Architecture

### File Structure
```
website/
├── index.html                          # Homepage
├── favicon.png                         # Site favicon (retain existing)
├── robots.txt                          # Search engine directives
├── sitemap.xml                         # XML sitemap
├── src/
│   ├── css/
│   │   └── styles.css                  # Complete design system + components
│   ├── js/
│   │   └── main.js                     # Navbar toggle, animations, pricing, FAQ
│   └── pages/
│       ├── features.html               # Feature showcase
│       ├── screenshots.html            # App gallery
│       ├── pricing.html                # Plans & comparison
│       ├── about.html                  # Company story
│       ├── support.html                # Help & contact
│       ├── download.html               # Platform downloads
│       ├── privacy.html                # Privacy policy
│       ├── terms.html                  # Terms of service (NEW)
│       └── blog.html                   # Blog landing (NEW)
├── assets/
│   └── images/
│       ├── app_icon.png                # App icon (retain)
│       ├── og-image.png                # Open Graph share image (1200×630)
│       ├── screenshots/                # App screenshots (WebP)
│       └── icons/                      # Platform icons, feature SVGs
```

### CSS Architecture (Single File)
```css
/* styles.css — Organized Sections */

/* 1. Design Tokens (CSS Variables)           ~50 lines   */
/* 2. Base Reset & Typography                 ~80 lines   */
/* 3. Layout (Container, Grid, Flexbox)       ~60 lines   */
/* 4. Components — Navbar                     ~120 lines  */
/* 5. Components — Buttons                    ~60 lines   */
/* 6. Components — Cards                      ~80 lines   */
/* 7. Components — Badges & Tags              ~30 lines   */
/* 8. Components — Feature Blocks             ~90 lines   */
/* 9. Components — Pricing                    ~120 lines  */
/* 10. Components — FAQ Accordion             ~50 lines   */
/* 11. Components — Footer                    ~100 lines  */
/* 12. Sections — Hero                        ~80 lines   */
/* 13. Sections — Trust Bar                   ~30 lines   */
/* 14. Sections — Testimonials                ~60 lines   */
/* 15. Sections — CSS App Mockups             ~150 lines  */
/* 16. Utility Classes                        ~40 lines   */
/* 17. Animations & Transitions               ~60 lines   */
/* 18. Responsive Breakpoints                 ~200 lines  */
/* ---                                                     */
/* Total estimated: ~1,400 lines (~22KB raw, ~5KB gzipped) */
```

### JavaScript Architecture (Single File)
```javascript
/* main.js — Organized Sections */

/* 1. Navbar — mobile toggle, scroll shadow, active state    */
/* 2. Scroll Animations — IntersectionObserver fade-in       */
/* 3. Pricing Toggle — Monthly/Annual price switch            */
/* 4. FAQ Accordion — expand/collapse with smooth animation   */
/* 5. Screenshot Lightbox — click to zoom (optional)          */
/* 6. Smooth Scroll — anchor link behavior                    */
/* 7. Analytics — GA4 event tracking helpers                  */
/* ---                                                         */
/* Total estimated: ~200 lines (~3KB raw, ~1.5KB gzipped)     */
```

### HTML Template (Shared Structure)
Every page follows this structure:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- Meta: charset, viewport, title, description -->
  <!-- OG & Twitter Cards -->
  <!-- Structured Data (JSON-LD) -->
  <!-- Preconnect: Google Fonts -->
  <!-- CSS: styles.css -->
  <!-- Favicon -->
  <!-- Analytics (GA4) -->
</head>
<body>
  <nav class="navbar">...</nav>         <!-- Shared navbar -->
  <main>
    <section class="hero">...</section>  <!-- Page-specific hero -->
    <!-- Page content sections -->
  </main>
  <footer class="footer">...</footer>   <!-- Shared footer -->
  <script src="main.js" defer></script>  <!-- JS at end -->
</body>
</html>
```

---

## 12. Responsive Design Breakpoints

### Breakpoints
```css
/* Mobile First — Base styles target mobile */

/* Small tablets and large phones */
@media (min-width: 640px) { /* sm */ }

/* Tablets */
@media (min-width: 768px) { /* md */ }

/* Small desktops */
@media (min-width: 1024px) { /* lg */ }

/* Large desktops */
@media (min-width: 1280px) { /* xl */ }
```

### Layout Adaptations
| Component | Mobile (< 768px) | Tablet (768-1024px) | Desktop (> 1024px) |
|-----------|-------------------|---------------------|---------------------|
| Navbar | Hamburger menu | Hamburger menu | Full horizontal nav |
| Hero | Stacked, text-only | Stacked + small mockup | Side-by-side with mockup |
| Feature Grid | 1 column | 2 columns | 3 columns |
| Pricing Cards | 1 column stacked | 2 columns | 3 columns inline |
| Feature Blocks | Stacked (text → image) | Side-by-side | Alternating left/right |
| Footer | 1 column stacked | 2 columns | 4 columns |
| CTAs | Full-width buttons | Auto-width inline | Auto-width inline |
| Comparison Table | Scrollable horizontal | Full visible | Full visible |

---

## 13. Accessibility (WCAG 2.1 AA)

### Checklist
- [ ] **Color Contrast:** All text meets 4.5:1 ratio (verified: `#10B981` on white = 3.0:1 ❌ — use `#059669` for small text on white backgrounds = 4.6:1 ✅)
- [ ] **Keyboard Navigation:** All interactive elements focusable with visible focus rings
- [ ] **ARIA Labels:** Hamburger menu, FAQ accordion, pricing toggle
- [ ] **Semantic HTML:** Proper use of `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`
- [ ] **Alt Text:** All images have descriptive alt text
- [ ] **Skip Navigation:** "Skip to main content" link for screen readers
- [ ] **Form Labels:** All form inputs have associated `<label>` elements
- [ ] **Reduced Motion:** `@media (prefers-reduced-motion: reduce)` disables animations
- [ ] **Font Size:** Base 16px, never smaller than 12px
- [ ] **Touch Targets:** Minimum 48×48px for mobile tap targets
- [ ] **Language:** `<html lang="en">` declared
- [ ] **Focus Management:** Modal/lightbox trap focus correctly

### Color Contrast Fixes
```css
/* Use darker green for body text on white */
.text-on-white { color: #059669; }  /* 4.6:1 ✅ */

/* Keep #10B981 for large text (18px+) and UI elements */
.heading-green { color: #10B981; }  /* 3.0:1 — OK for large text ✅ */

/* Buttons: white text on #10B981 = 3.4:1 — use bold 16px+ to pass */
.btn-primary { background: #10B981; color: #fff; font-weight: 600; }
```

---

## 14. Deployment & Hosting

### Firebase Hosting Configuration

**Existing `firebase.json` update:**
```json
{
  "hosting": {
    "public": "website",
    "ignore": ["firebase.json", "**/node_modules/**"],
    "headers": [
      {
        "source": "**/*.@(css|js)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000, immutable" }]
      },
      {
        "source": "**/*.@(png|jpg|jpeg|gif|webp|svg|ico)",
        "headers": [{ "key": "Cache-Control", "value": "max-age=31536000, immutable" }]
      },
      {
        "source": "**/*.html",
        "headers": [{ "key": "Cache-Control", "value": "max-age=3600" }]
      }
    ],
    "rewrites": [],
    "redirects": []
  }
}
```

### Deployment Command
```bash
firebase deploy --only hosting
```

### Pre-Deployment Checklist
- [ ] All HTML validated (W3C validator)
- [ ] All links verified (no broken links)
- [ ] Lighthouse score > 90 (Performance, SEO, Accessibility)
- [ ] Mobile responsive tested on: iPhone SE, iPhone 14, Pixel 7, iPad
- [ ] Cross-browser tested: Chrome, Firefox, Safari, Edge
- [ ] Open Graph preview verified (Facebook debugger, Twitter card validator)
- [ ] `sitemap.xml` updated with all URLs
- [ ] `robots.txt` allows indexing
- [ ] Google Analytics verified (real-time view)
- [ ] All CTAs link to correct app URLs
- [ ] Meta descriptions unique per page
- [ ] Favicon displays correctly

---

## 15. Implementation Phases & Milestones

### Phase 1 — Foundation (Core Pages)
**Scope:** 5 pages + design system

| Task | Deliverable | Priority |
|------|-------------|----------|
| Design system CSS | Complete `styles.css` with all tokens, components | 🔴 P0 |
| Homepage | `index.html` — full implementation | 🔴 P0 |
| Features page | `features.html` — all 22 modules | 🔴 P0 |
| Pricing page | `pricing.html` — plans, comparison, FAQ | 🔴 P0 |
| Download page | `download.html` — platform links | 🔴 P0 |
| Shared components | Navbar, footer, JS interactions | 🔴 P0 |

**Acceptance Criteria:**
- Lighthouse Performance > 90
- Mobile responsive on 3+ device sizes
- All 5 pages linked and navigable
- CTAs point to correct app/download URLs

### Phase 2 — Complete & Polish
**Scope:** Remaining pages + SEO + analytics

| Task | Deliverable | Priority |
|------|-------------|----------|
| About page | `about.html` | 🟡 P1 |
| Support page | `support.html` — FAQ + contact form | 🟡 P1 |
| Screenshots page | `screenshots.html` — gallery with lightbox | 🟡 P1 |
| Privacy policy | `privacy.html` | 🟡 P1 |
| Terms of service | `terms.html` | 🟡 P1 |
| SEO implementation | Structured data, OG tags, sitemap | 🟡 P1 |
| GA4 + Clarity setup | Analytics & heatmap tracking | 🟡 P1 |
| App screenshots | Capture & optimize screenshots | 🟡 P1 |

**Acceptance Criteria:**
- All 10 pages live
- Structured data validated (Google Rich Results Test)
- GA4 tracking verified
- Sitemap submitted to Search Console

### Phase 3 — Optimization & Growth
**Scope:** Content, CRO, blog

| Task | Deliverable | Priority |
|------|-------------|----------|
| Blog landing | `blog.html` — 4 placeholder articles | 🟢 P2 |
| Blog content | 2-3 SEO articles per month | 🟢 P2 |
| A/B testing | Hero headline + CTA experiments | 🟢 P2 |
| Testimonial collection | Real user quotes with photos | 🟢 P2 |
| Performance audit | Monthly Lighthouse + CWV report | 🟢 P2 |
| Link building | Guest posts, directory listings, partnerships | 🟢 P2 |
| Video demo | Record walkthrough + embed | 🟢 P2 |

---

## Appendix A — Complete Feature-to-Page Mapping

| App Module | Website Page | Section | SEO Keyword Target |
|-----------|-------------|---------|-------------------|
| POS Billing | Features | Billing & Orders | restaurant billing app, hotel POS software |
| Orders | Features | Billing & Orders | restaurant order management |
| Kitchen Display | Features | Billing & Orders | kitchen display system restaurant |
| GST Export | Features | Billing & Orders | GST billing software hotel |
| Tables | Features | Table & Reservations | table management restaurant |
| Reservations | Features | Table & Reservations | hotel reservation system |
| Products | Features | Menu & Products | restaurant menu management |
| Combos | Features | Menu & Products | meal combo restaurant |
| Daily Specials | Features | Menu & Products | daily specials menu system |
| Staff Management | Features | Staff & HR | hotel staff management software |
| Attendance | Features | Staff & HR | staff attendance app hotel |
| Shift Scheduling | Features | Staff & HR | shift scheduling restaurant |
| Tasks | Features | Staff & HR | task management hotel staff |
| Salary | Features | Staff & HR | salary management hotel |
| Cash Register | Features | Staff & HR | cash register management |
| Messages | Features | Staff & HR | hotel staff messaging |
| Ingredients | Features | Inventory | restaurant inventory management |
| Vendors | Features | Inventory | vendor management hotel |
| Wastage | Features | Inventory | food wastage tracking restaurant |
| Customer Portal | Features | Customer Engagement | QR code menu restaurant |
| Coupons | Features | Customer Engagement | restaurant coupon discount |
| Feedback | Features | Customer Engagement | customer feedback hotel |
| Licenses | Features | Compliance | FSSAI license tracking |
| Equipment | Features | Compliance | equipment maintenance hotel |
| Complaints | Features | Compliance | complaint management hotel |
| Events | Features | Compliance | banquet event management |
| Dashboard | Features | Analytics | hotel analytics dashboard |
| 9 Reports | Features | Analytics | restaurant analytics reports |
| Settings | — | — | — |
| Notifications | — | — | — |
| Subscription | Pricing | Plans | hotel management pricing |
| Khata | Features | Billing & Orders | khata ledger hotel credit |
| Customer-facing URLs | Homepage + Features | Customer Portal | QR ordering restaurant |

---

## Appendix B — Competitor Reference (For Design Inspiration)

| Competitor | URL | What to Study |
|-----------|-----|---------------|
| Petpooja | petpooja.com | Indian restaurant POS — feature layout, pricing structure |
| Torqus | torqus.com | Restaurant management — design quality, testimonials |
| Posist | posist.com | Enterprise hospitality — content depth, SEO |
| LimeTray | limetray.com | Online ordering focus — customer portal messaging |
| goFrugal | gofrugal.com | Indian SaaS — pricing page, trust signals |
| UrbanPiper | urbanpiper.com | Modern design — homepage hero, conversion flow |

*Study for design patterns and content strategy only. Do not copy any content or code.*

---

## Appendix C — Content Assets Needed

| Asset | Description | Source | Status |
|-------|-------------|--------|--------|
| App Icon | 512×512 PNG | Existing (`assets/images/app_icon.png`) | ✅ Ready |
| Favicon | 32×32 PNG | Existing (`favicon.png`) | ✅ Ready |
| OG Share Image | 1200×630 PNG hero card | Create new | ❌ Needed |
| App Screenshots (12) | WebP, 1280×800 per screen | Capture from running app | ❌ Needed |
| Demo Video | 2-3 min walkthrough | Record screen capture | ❌ Needed |
| Testimonials (5-10) | Name, hotel, city, quote | Collect from users | ❌ Needed |
| Team Photos | If showing team on About | Collect | ❌ Optional |
| Play Store Badge | Official Google badge | Google Brand Assets | ❌ Needed |
| Hotel Stock Images | Hero backgrounds (optional) | Use CSS mockups or buy | ❌ Optional |

---

## Appendix D — URL Mapping (Old → New)

| Old URL (Retail) | New URL (Hotel) | Action |
|-----------------|----------------|--------|
| `stores.tulasierp.com` | `hotels.tulasierp.com` (or `tulasierp.com`) | 301 redirect |
| `/app/` | `/app/` | Keep — Flutter web app |
| All `TULASI STORES` references | `Tulasi Hotels` | Replace throughout |

---

*End of Implementation Plan*
