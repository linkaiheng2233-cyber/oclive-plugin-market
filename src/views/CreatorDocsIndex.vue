<script setup lang="ts">
import { RouterLink } from 'vue-router'

const base = import.meta.env.BASE_URL
const githubDocs =
  'https://github.com/linkaiheng2233-cyber/oclivenewnew/tree/main/creator-docs'

const cards = [
  {
    title: '角色包配置指南',
    desc: '了解 ui.json：整壳、插槽、主题与布局；以及在编写器中如何配置。',
    to: '/docs/creator/ui-json-guide',
  },
  {
    title: '常见问题',
    desc: '导出 ui.json、主题不生效、整壳与插槽顺序、多角色差异等。',
    to: '/docs/creator/faq',
  },
  {
    title: '版本兼容性',
    desc: '编写器与主程序 0.2.x 搭配建议与升级提示。',
    to: '/docs/creator/compatibility',
  },
] as const
</script>

<template>
  <div class="creator-docs">
    <header class="hero">
      <h1>欢迎来到 Oclive 创作者文档</h1>
      <p class="lead">
        面向使用<strong>编写器</strong>制作角色包的创作者：配置前端布局、理解
        <code>ui.json</code>、排查常见问题。插件开发与深度定制请参阅底部 GitHub 链接。
      </p>
    </header>

    <ul class="cards" role="list">
      <li v-for="c in cards" :key="c.to">
        <RouterLink :to="c.to" class="card">
          <h2>{{ c.title }}</h2>
          <p>{{ c.desc }}</p>
          <span class="more">阅读 →</span>
        </RouterLink>
      </li>
    </ul>

    <footer class="foot">
      <p>
        需要开发插件或深度定制？请访问
        <a :href="githubDocs" target="_blank" rel="noopener noreferrer">GitHub 文档仓库（creator-docs）</a>。
      </p>
      <p class="muted">
        纯 Markdown 源文件也可在仓库中浏览：
        <a :href="`${base}docs/creator/index.md`" target="_blank" rel="noopener noreferrer">index.md</a>
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
