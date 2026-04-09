<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="hero">
    <p class="eyebrow">发现角色包、侧车插件与可替换模块</p>
    <h1>用图集与卡片浏览，点进看详情</h1>
    <p class="lead">
      面向使用者：按兴趣逛<strong>角色包</strong>、<strong>插件</strong>与<strong>模块</strong>，不必了解创作者如何上架。
      需要登记作品时，请点右上角<strong>上传</strong>。
    </p>
    <div class="tiles">
      <RouterLink to="/packs" class="tile">
        <span class="tile-k">角色包</span>
        <span class="tile-d">完整包与子模块 · 搜索筛选 · 自由组合</span>
      </RouterLink>
      <RouterLink to="/plugins" class="tile">
        <span class="tile-k">插件</span>
        <span class="tile-d">Remote 侧车 · 与角色包联动</span>
      </RouterLink>
      <RouterLink to="/modules" class="tile">
        <span class="tile-k">可替换模块</span>
        <span class="tile-d">记忆、情感等系统示意</span>
      </RouterLink>
      <RouterLink to="/versions" class="tile">
        <span class="tile-k">版本与下载</span>
        <span class="tile-d">启动器、编写器、oclive 的 GitHub 发布列表</span>
      </RouterLink>
      <RouterLink to="/me" class="tile">
        <span class="tile-k">个人主页</span>
        <span class="tile-d">展示与自定义（占位）</span>
      </RouterLink>
    </div>
  </section>
</template>

<style scoped>
.hero {
  padding: 28px 0 40px;
}
.eyebrow {
  margin: 0 0 10px;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--accent);
}
h1 {
  margin: 0 0 14px;
  font-size: clamp(1.45rem, 3.5vw, 1.9rem);
  letter-spacing: -0.03em;
  line-height: 1.2;
}
.lead {
  margin: 0 0 28px;
  max-width: 52ch;
  color: var(--fg-muted);
  line-height: 1.6;
  font-size: 1.02rem;
}
.tiles {
  display: grid;
  gap: 14px;
  grid-template-columns: 1fr;
}
@media (min-width: 640px) {
  .tiles {
    grid-template-columns: repeat(2, 1fr);
  }
}
.tile {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 18px 18px;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--surface);
  text-decoration: none;
  color: inherit;
  box-shadow: var(--shadow);
  transition: border-color 0.15s ease, transform 0.15s ease;
}
.tile:hover {
  border-color: var(--accent-soft);
  transform: translateY(-1px);
}
.tile-k {
  font-weight: 700;
  font-size: 1.05rem;
}
.tile-d {
  font-size: 0.9rem;
  color: var(--fg-muted);
  line-height: 1.45;
}
</style>
