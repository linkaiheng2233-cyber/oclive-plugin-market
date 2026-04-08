import { copyFileSync, existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

const __dirname = dirname(fileURLToPath(import.meta.url))

/** GitHub Pages 项目站：无真实文件的路径会 404；提供与 index 相同的 404.html 让 Vue Router 接管（刷新 / 直达子路径） */
function spaFallback404() {
  return {
    name: 'spa-fallback-404',
    apply: 'build' as const,
    closeBundle() {
      const outDir = resolve(__dirname, 'dist')
      const indexHtml = resolve(outDir, 'index.html')
      if (existsSync(indexHtml)) {
        copyFileSync(indexHtml, resolve(outDir, '404.html'))
      }
    },
  }
}

/** 本地开发默认 `/`；GitHub Pages 项目页在 CI 里设 `VITE_BASE=/仓库名/` */
export default defineConfig({
  plugins: [vue(), spaFallback404()],
  base: process.env.VITE_BASE || '/',
  server: {
    port: 5173,
    /** 与 Supabase Redirect URLs（localhost:5173）一致；占用时直接报错，避免静默换端口导致邮件链接打不开 */
    strictPort: true,
  },
})
