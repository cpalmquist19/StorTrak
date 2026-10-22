# StorTrak — guidance for Claude

StorTrak is the internal rental/billing app for **Piedmont Stor-All**, a fictional
self-storage company with three facilities. Everything here is fictional — never
reference, name, or imitate real companies, people, or products in code, data, or docs.

## Purpose

StorTrak is an intentionally vulnerable training and benchmark app, in the tradition
of OWASP WebGoat and DVWA. It is used to evaluate an AI refactoring agent. It runs
only on localhost and is never deployed.

## This codebase is intentionally legacy

The bad code is deliberate. StorTrak is a benchmark target for an AI refactoring agent.

**Do NOT, unless explicitly asked:**
- modernize, refactor, or restructure application code
- parameterize queries (no `cfqueryparam` retrofits)
- add `var` / `local.` scoping
- rename variables, functions, files, or tables
- "fix" code smells, dead code, duplication, typos, or inconsistent style
- convert tags to script, or Application.cfm to Application.cfc

When adding legacy code, write it the way the original author of that era would have.

## Eras

Every application file belongs to one era and must match that era's style.
Put the author's initials and year in the file header comment (e.g. `<!--- GH 2006 --->`).

| Era  | Author              | Style |
|------|---------------------|-------|
| 2006 | Gary Hollis (GH)    | Tag-based CFML. `Application.cfm`. `<cfinclude template="hdr.cfm">` / `ftr.cfm` on every page. Table layouts, inline styles, `<font>` tags. Inline `<cfquery>` in pages, values concatenated into SQL. |
| 2011 | Dwayne Jarrett (DJ) | UDF library in `/inc/functions.cfm`, included globally. `<cffunction>` with no `var` scoping. Some `<cfscript>` blocks. |
| 2014 | Tanya Marsh (TM)    | Half-finished ColdBox app under `/webroot/cb/`. Partially wired handlers/views; some features exist in both old pages and cb/. |
| 2019 | Rick Jensen (RJ)    | Hotfix files in `/webroot/fix/`. Copy-pasted page variants, quick patches, `_v2`/`_new` suffixes. |
| 2022 | contractor (KP)     | jQuery touch-ups on existing pages, Lucee 5 bump and the compatibility shims that came with it. |

## Infrastructure is NOT legacy

These must be clean, modern, and well-maintained:
- `docker-compose.yml`, `docker/`, `server.json`, `box.json`, `.cfconfig.json`
- `db/` scripts (schema, seed loading)
- `tests/`
- the seed data generator
- `Makefile`, `README.md`

**The schema is legacy; the loading is not.** `db/schema.sql` is Gary's 2006 schema
and keeps its scars: no foreign keys, no lookup tables, no indexes beyond primary keys,
FLOAT money, plain-text gate codes, MD5 passwords and inconsistent naming. Don't
"improve" it. The machinery that loads it (the `make reset` recipe, docker init,
any future seed loader) is infrastructure and stays clean. Keep `CREATE DATABASE`
and other setup out of `schema.sql`. Gary's file is just his tables.

Pin exact image/engine versions. Keep secrets out of legacy files (the DSN is defined
in `.cfconfig.json`, not in application code).

## Hard rules
- Never create a `bench/` folder.
- Never document, list, comment on, or hint at seeded bugs anywhere in this repo
  (no TODOs pointing at them, no "intentional bug" comments, no answer keys).
- Never reference real companies.

## Local dev
- `make up` / `make down` / `make reset` (wipe + reload DB) / `make logs`
- App: http://127.0.0.1:8080 — DSN name: `stortrak`
