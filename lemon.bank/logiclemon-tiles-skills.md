# LogicLemon AI · Skills Library v1

**Source:** distilled from `skills.raw.md` (VoltAgent's *Awesome Agent Skills* — 1,100+ entries).
**Filter:** kept only what we'll plausibly use across the seven LLai tiles. Generic, broken, off-topic, blockchain/mobile/desktop, and AI-template-stuffed entries dropped.
**Discipline:** every entry has author, canonical link, and a one-line "why we care."

---

## Project-wide foundation

These apply to every tile we ship.

### The engine

| Skill | Source | Why we care |
|---|---|---|
| **composiohq/composio** | [link](https://officialskills.sh/composiohq/skills/composio) | The product is built on this. Multi-tenant OAuth + tool execution across 1,000+ services. Every tile starts here. |

### Auth

| Skill | Source | Why we care |
|---|---|---|
| **better-auth/best-practices** | [link](https://officialskills.sh/better-auth/skills/best-practices) | Lighter than Auth0; opinionated for a SaaS we control end-to-end. |
| **better-auth/create-auth** | [link](https://officialskills.sh/better-auth/skills/create-auth) | Initial setup checklist. |
| **better-auth/organization** | [link](https://officialskills.sh/better-auth/skills/organization) | Multi-tenant org primitives — matches our `orgs` / `org_members` schema. |
| **better-auth/twoFactor** | [link](https://officialskills.sh/better-auth/skills/twoFactor) | Required for enterprise tier. |

> *Auth0 has a complete skill set in `skills.raw.md` (line 775). Switch to it if Better Auth doesn't cover an enterprise SSO requirement; otherwise stay with Better Auth.*

### Database (pick one)

| Skill | Source | Why we care |
|---|---|---|
| **supabase/postgres-best-practices** | [link](https://officialskills.sh/supabase/skills/postgres-best-practices) | If we run on Supabase. RLS-first guidance — matches our schema's RLS readiness. |
| **neondatabase/neon-postgres** | [link](https://officialskills.sh/neondatabase/skills/neon-postgres) | If we run on Neon. Branching for preview deploys is gold for a multi-environment .com/.org/.uk setup. |
| **neondatabase/neon-postgres-egress-optimizer** | [link](https://officialskills.sh/neondatabase/skills/neon-postgres-egress-optimizer) | Watch egress when Cloudflare Workers query a Neon DB across regions. |

### Frontend (the showroom — never a terminal)

| Skill | Source | Why we care |
|---|---|---|
| **vercel-labs/react-best-practices** | [link](https://officialskills.sh/vercel-labs/skills/react-best-practices) | Tile gallery is React; this raises the floor on every component we ship. |
| **vercel-labs/web-design-guidelines** | [link](https://officialskills.sh/vercel-labs/skills/web-design-guidelines) | Visual quality bar. |
| **vercel-labs/composition-patterns** | [link](https://officialskills.sh/vercel-labs/skills/composition-patterns) | The action panel is one schema-driven form repeated seven times — these patterns matter. |
| **anthropics/frontend-design** | [link](https://officialskills.sh/anthropics/skills/frontend-design) | Design instincts for editorial/product UIs. |
| **openai/frontend-skill** | [link](https://officialskills.sh/openai/skills/frontend-skill) | Restrained composition for landing pages — directly applicable to ll.com. |
| **addyosmani/web-quality-audit** | [link](https://officialskills.sh/addyosmani/skills/web-quality-audit) | Chrome team. Lighthouse-grade audits before launch. |
| **addyosmani/core-web-vitals** | [link](https://officialskills.sh/addyosmani/skills/core-web-vitals) | LCP, INP, CLS — what enterprise procurement teams check. |
| **addyosmani/accessibility** | [link](https://officialskills.sh/addyosmani/skills/accessibility) | WCAG. Required for enterprise sales. |

### Hosting (we're on Cloudflare)

| Skill | Source | Why we care |
|---|---|---|
| **cloudflare/cloudflare** | [link](https://officialskills.sh/cloudflare/skills/cloudflare) | The whole platform reference. |
| **cloudflare/wrangler** | [link](https://officialskills.sh/cloudflare/skills/wrangler) | Deploy/manage Workers, Pages, R2, D1, Vectorize, Queues. |
| **cloudflare/workers-best-practices** | [link](https://officialskills.sh/cloudflare/skills/workers-best-practices) | Production guardrails; review every Worker against this. |
| **cloudflare/durable-objects** | [link](https://officialskills.sh/cloudflare/skills/durable-objects) | Per-org stateful coordination — useful for the outcome worker. |
| **cloudflare/cloudflare-email-service** | [link](https://officialskills.sh/cloudflare/skills/cloudflare-email-service) | Free transactional email; alternative to Resend. |

### Observability (production-grade requires this)

| Skill | Source | Why we care |
|---|---|---|
| **getsentry/sentry-react-sdk** | [link](https://officialskills.sh/getsentry/skills/sentry-react-sdk) | Frontend error monitoring. |
| **getsentry/sentry-node-sdk** | [link](https://officialskills.sh/getsentry/skills/sentry-node-sdk) | Backend error monitoring (if we have a Node service). |
| **getsentry/sentry-cloudflare-sdk** | [link](https://officialskills.sh/getsentry/skills/sentry-cloudflare-sdk) | Errors inside Workers/Pages/Durable Objects. |
| **getsentry/sentry-setup-ai-monitoring** | [link](https://officialskills.sh/getsentry/skills/sentry-setup-ai-monitoring) | Instruments Anthropic/OpenAI calls — visibility into LLM cost & failure modes. |
| **getsentry/sentry-create-alert** | [link](https://officialskills.sh/getsentry/skills/sentry-create-alert) | Alerts route to Slack/PagerDuty. |
| **openai/sentry** | [link](https://officialskills.sh/openai/skills/sentry) | Inspect Sentry issues from inside agent workflows — useful for dogfood ops. |

### Security (do once, sleep well)

| Skill | Source | Why we care |
|---|---|---|
| **trailofbits/insecure-defaults** | [link](https://officialskills.sh/trailofbits/skills/insecure-defaults) | Catches hardcoded secrets, default creds, weak crypto. Run before every release. |
| **trailofbits/sharp-edges** | [link](https://officialskills.sh/trailofbits/skills/sharp-edges) | Identifies error-prone APIs in our stack. |
| **trailofbits/static-analysis** | [link](https://officialskills.sh/trailofbits/skills/static-analysis) | CodeQL, Semgrep, SARIF. Free CI gate. |
| **openai/security-best-practices** | [link](https://officialskills.sh/openai/skills/security-best-practices) | Language-specific vulnerability review. |
| **wrsmith108/varlock-claude-skill** | [link](https://github.com/wrsmith108/varlock-claude-skill) | Secret management hygiene for Claude/Codex sessions — prevents secrets leaking into git or logs. |

### Workflow (working with junior agents)

| Skill | Source | Why we care |
|---|---|---|
| **mattpocock/skills** | [link](https://github.com/mattpocock/skills) | 17 dev workflow skills (PRD writing, TDD, refactoring plans). Battle-tested. |
| **obra/test-driven-development** | [link](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md) | Tests before code — required when junior agents write the implementation. |
| **obra/systematic-debugging** | [link](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md) | Methodical debugging — pin to every junior agent. |
| **obra/verification-before-completion** | [link](https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md) | "Did it actually work?" check. Closes the agent illusion-of-progress gap. |
| **obra/using-git-worktrees** | [link](https://github.com/obra/superpowers/blob/main/skills/using-git-worktrees/SKILL.md) | Parallel agent branches without stepping on each other. |
| **callstackincubator/github** | [link](https://officialskills.sh/callstackincubator/skills/github) | PR/branch/review workflow patterns. |
| **openai/yeet** | [link](https://officialskills.sh/openai/skills/yeet) | Stage → commit → push → PR via CLI. Trivial but saves keystrokes for the junior agent. |

---

## Per-tile skill picks

Every tile uses **composiohq/composio** as the OAuth + execution layer. The picks below are *additive* — what to load on top of the foundation when working on that tile.

### 1. Inbox Triage  ·  Gmail

| Skill | Source | Role |
|---|---|---|
| **googleworkspace/gws-gmail** | [link](https://officialskills.sh/googleworkspace/skills/gws-gmail) | Send/read/manage Gmail via the `gws` CLI — useful for backend cron flows where Composio isn't a fit. |
| **googleworkspace/gws-shared** | [link](https://officialskills.sh/googleworkspace/skills/gws-shared) | Shared auth + flags for any `gws-*` skill. |
| **google-gemini/gemini-api-dev** | [link](https://officialskills.sh/google-gemini/skills/gemini-api-dev) | Cheap-fast LLM for the classify pass; falls back to Anthropic for drafting. |
| **resend/agent-email-inbox** | [link](https://github.com/resend/resend-skills/tree/main/skills/agent-email-inbox) | Inbox-management primitives — cross-pollinates with our triage logic. |

### 2. Standup Concierge  ·  Slack

| Skill | Source | Role |
|---|---|---|
| *(no Slack-specific skill in `skills.raw.md`)* | — | Composio's Slack toolkit covers everything. Don't introduce a second Slack abstraction. |
| **getsentry/sentry-create-alert** | [link](https://officialskills.sh/getsentry/skills/sentry-create-alert) | If standup posts to a channel, alerts on standup-failures should too. Same Slack tokens. |

### 3. PR Review Brief  ·  GitHub

| Skill | Source | Role |
|---|---|---|
| **callstackincubator/github** | [link](https://officialskills.sh/callstackincubator/skills/github) | PR/branch/review patterns — directly informs the brief format. |
| **coderabbitai/code-review** | [link](https://officialskills.sh/coderabbitai/skills/code-review) | Reference implementation of AI-assisted PR review. We're not bundling CodeRabbit, but their skill is the bar. |
| **coderabbitai/autofix** | [link](https://officialskills.sh/coderabbitai/skills/autofix) | Pattern for "draft a fix from a review comment." Roadmap. |
| **openai/gh-address-comments** | [link](https://officialskills.sh/openai/skills/gh-address-comments) | Address PR review comments via CLI — model for our "draft reviewer comments" output. |
| **openai/gh-fix-ci** | [link](https://officialskills.sh/openai/skills/gh-fix-ci) | Pattern for pulling CI logs into the brief. |

### 4. Calendar Choreographer  ·  Calendar + LinkedIn + Gmail

| Skill | Source | Role |
|---|---|---|
| **googleworkspace/gws-calendar** | [link](https://officialskills.sh/googleworkspace/skills/gws-calendar) | Manage calendar events. Used for writing briefs into event descriptions. |
| **googleworkspace/gws-gmail** | [link](https://officialskills.sh/googleworkspace/skills/gws-gmail) | Pull thread context for attendees. |
| **googleworkspace/gws-people** | [link](https://officialskills.sh/googleworkspace/skills/gws-people) | Resolve attendee identities. |
| **brave/web-search** | [link](https://officialskills.sh/brave/skills/web-search) | Cheap web context for external attendees (news, recent posts). |
| **brave/answers** | [link](https://officialskills.sh/brave/skills/answers) | Grounded one-line attendee summaries. |

### 5. Knowledge Tender  ·  Notion

| Skill | Source | Role |
|---|---|---|
| **makenotion/knowledge-capture** | [link](https://officialskills.sh/makenotion/skills/knowledge-capture) | Official Notion: turn conversations into structured pages. **Core dependency.** |
| **makenotion/meeting-intelligence** | [link](https://officialskills.sh/makenotion/skills/meeting-intelligence) | Pre-reads + agendas; overlaps with Calendar Choreographer. |
| **makenotion/research-documentation** | [link](https://officialskills.sh/makenotion/skills/research-documentation) | Search + synthesize across a Notion workspace. |
| **makenotion/spec-to-implementation** | [link](https://officialskills.sh/makenotion/skills/spec-to-implementation) | Specs → tasks. Roadmap for an enterprise tile variant. |
| **openai/notion-knowledge-capture** | [link](https://officialskills.sh/openai/skills/notion-knowledge-capture) | OpenAI's wrapper of the same idea — useful as a reference implementation. |

### 6. Revenue Pulse  ·  Stripe

| Skill | Source | Role |
|---|---|---|
| **stripe/stripe-best-practices** | [link](https://officialskills.sh/stripe/skills/stripe-best-practices) | **Pin to every Revenue Pulse PR.** Idempotency, webhooks, error handling. |
| **stripe/upgrade-stripe** | [link](https://officialskills.sh/stripe/skills/upgrade-stripe) | When the Stripe API version changes, run this. |
| **EveryInc/charlie-cfo-skill** | [link](https://github.com/EveryInc/charlie-cfo-skill) | "Bootstrapped CFO" lens for the metrics we surface. Inform the digest content, not the technical implementation. |

### 7. Lead Warmer  ·  LinkedIn + HubSpot + Gmail

| Skill | Source | Role |
|---|---|---|
| **resend/resend** | [link](https://github.com/resend/resend-skills/tree/main/skills/resend) | Send drafted outreach via Resend if Gmail throttling becomes an issue. |
| **resend/email-best-practices** | [link](https://github.com/resend/resend-skills/tree/main/skills/email-best-practices) | Deliverability hygiene — critical for cold outreach. |
| **resend/react-email** | [link](https://github.com/resend/resend-skills/tree/main/skills/react-email) | Component-based email templates. |
| **firecrawl/firecrawl-build-search** | [link](https://officialskills.sh/firecrawl/skills/firecrawl-build-search) | Discover prospects via query-first search. |
| **brave/web-search** | [link](https://officialskills.sh/brave/skills/web-search) | Cheap fallback for prospect enrichment. |
| **browserbase/browser** | [link](https://officialskills.sh/browserbase/skills/browser) | LinkedIn doesn't have a public API. Browserbase is how we'll actually scrape, with cookie-sync to avoid relogin. |
| **browserbase/cookie-sync** | [link](https://officialskills.sh/browserbase/skills/cookie-sync) | Persistent LinkedIn session for scraping. |

---

## Roadmap & nice-to-haves

Skills we don't need yet but should remember exist.

| Skill | Source | When we'd add it |
|---|---|---|
| **anthropics/mcp-builder** | [link](https://officialskills.sh/anthropics/skills/mcp-builder) | When clients ask "can LLai talk to *our* internal tool?" → build a private MCP server. |
| **figma/figma-implement-design** | [link](https://officialskills.sh/figma/skills/figma-implement-design) | When we hire a designer and they hand us Figma files for the action panels. |
| **anthropics/web-artifacts-builder** | [link](https://officialskills.sh/anthropics/skills/web-artifacts-builder) | If we add an "embed this digest" feature for clients to share results. |
| **tinybirdco/tinybird-best-practices** | [link](https://officialskills.sh/tinybirdco/skills/tinybird-best-practices) | When `outcomes` analytics outgrow Postgres. Real-time meter dashboards for clients. |
| **clickhouse/clickhouse-best-practices** | [link](https://officialskills.sh/clickhouse/skills/clickhouse-best-practices) | Alternative to Tinybird for the same use case. |
| **NeoLabHQ/sdd** | [link](https://github.com/NeoLabHQ/context-engineering-kit/tree/master/plugins/sdd) | Spec-driven development workflow with LLM-as-judge gates. Useful when the team grows. |
| **NeoLabHQ/code-review** | [link](https://github.com/NeoLabHQ/context-engineering-kit/tree/master/plugins/code-review) | Multi-agent PR review — pair with our PR Review Brief tile. |
| **hamelsmu/eval-audit** + sibling skills | [link](https://github.com/hamelsmu/prompts/tree/main/evals-skills) | When we have enough usage to do real evals on triage classification quality. |

---

## The drop list (and why)

Categories we explicitly skipped from `skills.raw.md`. Don't waste hours re-evaluating these.

| Dropped | Reason |
|---|---|
| **Trail of Bits blockchain skills** (smart contracts, Slither, etc.) | Not in scope. We're not auditing Solidity. |
| **Microsoft Azure SDK** (133 skills, 6 languages) | We're on Cloudflare. |
| **Hugging Face training/dataset skills** | We use frontier APIs, not custom-trained models. |
| **Expo, Flutter, React Native, SwiftUI, Kotlin, .NET, Java, Rust SDKs from Microsoft/Apple/Google** | LLai is a web SaaS. No mobile/desktop. |
| **Coinbase, Binance, x402** | Not a payments product. Stripe is enough. |
| **WordPress development skills** | We're not on WordPress. |
| **Marketing skills by Corey Haines / Kim Barrett / Dean Peters / Pawel Huryn** | Useful for *content* but not for building the product. Revisit when we're writing the launch sequence. |
| **n8n Automation** | Composio supersedes the use cases we'd need from n8n. |
| **Productivity skills like resume-skill, speed-reader, translate-book** | Personal-productivity tools, not infrastructure. |
| **Generic "best-practices" skills with vague descriptions** | If we can't tell from the description what changes when we adopt it, it's not worth loading. |
| **Community skills with no author authority** | The file warns about this in its Quality Criteria. We bias to official + named authors. |

---

## Update protocol

When `skills.raw.md` ships a new version (it's actively maintained):

1. `diff` the new file against the version this library was built from.
2. For each new entry: ask "does it serve one of our seven tiles, or our foundation, or our roadmap?"
3. If yes: add it to the right section above with a one-line "why we care."
4. If no: do nothing. The drop list is a feature, not a bug.

The library stays small *on purpose*. Every entry should pay rent.
