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

**Follow-up:** forum (`Forum*View`), admin (`AdminView`), account (`PersonalView`), browse/detail submit labels, and embedded creator-docs shells still contain hard-coded Chinese in templates or `types.ts` display names. Extend `market.*` (or split `marketForum.*`) and wire `useI18n` / `t()` there for full EN parity.

## Build

- `npm run build`
