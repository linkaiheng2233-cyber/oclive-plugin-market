<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
const base = import.meta.env.BASE_URL
const githubDocs =
  'https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/creator-docs'

const cardDefs = [
  { key: 'uiJson' as const, to: '/docs/creator/ui-json-guide' },
  { key: 'faq' as const, to: '/docs/creator/faq' },
  { key: 'compatibility' as const, to: '/docs/creator/compatibility' },
  { key: 'pluginSlots' as const, to: '/docs/creator/plugin-slots-hotkeys' },
]

const cards = computed(() =>
  cardDefs.map((c) => ({
    to: c.to,
    title: t(`market.creatorDocs.cards.${c.key}.title`),
    desc: t(`market.creatorDocs.cards.${c.key}.desc`),
  }))
)
</script>

<template>
  <div class="creator-docs">
    <header class="hero">
      <h1>{{ t('market.creatorDocs.heroTitle') }}</h1>
      <i18n-t keypath="market.creatorDocs.heroLead" tag="p" class="lead">
        <template #editor>
          <strong>{{ t('market.creatorDocs.editorStrong') }}</strong>
        </template>
        <template #uiJson>
          <code>ui.json</code>
        </template>
      </i18n-t>
    </header>

    <ul class="cards" role="list">
      <li v-for="c in cards" :key="c.to">
        <RouterLink :to="c.to" class="card">
          <h2>{{ c.title }}</h2>
          <p>{{ c.desc }}</p>
          <span class="more">{{ t('market.creatorDocs.readMore') }}</span>
        </RouterLink>
      </li>
    </ul>

    <footer class="foot">
      <p>
        {{ t('market.creatorDocs.footDevPrefix') }}
        <a :href="githubDocs" target="_blank" rel="noopener noreferrer">{{ t('market.creatorDocs.footDevLink') }}</a>
        {{ t('market.creatorDocs.footDevSuffix') }}
      </p>
      <p class="muted">
        {{ t('market.creatorDocs.footMdPrefix') }}
        <a :href="`${base}docs/creator/index.md`" target="_blank" rel="noopener noreferrer">{{
          t('market.creatorDocs.footMdLink')
        }}</a>
      </p>
    </footer>
  </div>
</template>

<style scoped>
.creator-docs {
  max-width: 720px;
  margin: 0 auto;
}

.hero {
  margin-bottom: 28px;
}

.hero h1 {
  font-size: 1.65rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin: 0 0 12px;
  color: var(--fg);
}

.lead {
  margin: 0;
  font-size: 1rem;
  color: var(--fg-muted);
  line-height: 1.6;
}

.lead code {
  font-size: 0.9em;
  padding: 1px 6px;
  border-radius: 4px;
  background: var(--code-bg);
}

.cards {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.card {
  display: block;
  padding: 18px 20px;
  border-radius: 12px;
  border: 1px solid var(--border);
  background: var(--surface);
  text-decoration: none;
  color: inherit;
  box-shadow: var(--shadow);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.card:hover {
  border-color: var(--accent-soft);
  box-shadow: 0 2px 8px rgba(58, 52, 42, 0.08);
}

.card h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
  font-weight: 650;
  color: var(--accent);
}

.card p {
  margin: 0;
  font-size: 0.92rem;
  color: var(--fg-muted);
  line-height: 1.5;
}

.more {
  display: inline-block;
  margin-top: 12px;
  font-size: 0.88rem;
  font-weight: 600;
  color: var(--accent);
}

.foot {
  margin-top: 36px;
  padding-top: 22px;
  border-top: 1px solid var(--border);
  font-size: 0.9rem;
  color: var(--fg-muted);
}

.foot p {
  margin: 0 0 10px;
}

.foot a {
  color: var(--accent);
  font-weight: 600;
}

.muted {
  font-size: 0.85rem;
  color: var(--fg-soft);
}
</style>
