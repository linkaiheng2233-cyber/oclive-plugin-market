import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/** 本地开发默认 `/`；GitHub Pages 项目页在 CI 里设 `VITE_BASE=/仓库名/` */
export default defineConfig({
  plugins: [vue()],
  base: process.env.VITE_BASE || '/',
  server: {
    port: 5173,
    /** 与 Supabase Redirect URLs（localhost:5173）一致；占用时直接报错，避免静默换端口导致邮件链接打不开 */
    strictPort: true,
  },
})
