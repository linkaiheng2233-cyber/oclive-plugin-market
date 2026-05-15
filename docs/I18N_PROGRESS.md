# I18N progress (oclive-plugin-market)

## Phase 0 — vue-i18n plan (locked)

- **Dependency**: `vue-i18n@^11` (same major family as oclivenewnew / pack-editor).
- **Layout**: `src/i18n/index.ts` — `createI18n({ legacy: false, locale, fallbackLocale: "zh-CN", messages })`.
- **Storage key**: `LOCALE_PREF_KEY = "oclive.appLocale"` (shared with host / editor / launcher for a consistent UX).
- **API**: `getLocalePreference`, `setLocalePreference`, `resolveLocaleTag`, `getBrowserLocaleTag` mirroring oclivenewnew `src/i18n/index.ts`.
- **Wire-up**: `src/main.ts` — `app.use(i18n)` before `mount`.

## CJK inventory

Command: `rg -l "\\p{Han}" --glob "*.vue" --glob "*.ts" src`

Covers views (`HomeView`, `BrowseView`, forum views, admin, …), `AppHeader.vue`, and i18n under `src/i18n/locales/` plus `src/composables/useMarketCopy.ts`.

**Follow-up:** `Forum*View`, `VersionsView`, `CreatorDocs*`, `AdminView` filters, `AvatarImg` alt wired to `market.*` (zh/en). Remaining: `AnnouncementsView` if any literals, `types.ts` comments only, embedded `.md` bodies stay Chinese.

## Build

- `npm run build`
