import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/** 本地开发默认 `/`；GitHub Pages 项目页在 CI 里设 `VITE_BASE=/仓库名/` */
export default defineConfig({
  plugins: [vue()],
  base: process.env.VITE_BASE || '/',
})
