/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL?: string
  readonly VITE_SUPABASE_ANON_KEY?: string
  readonly VITE_ADMIN_EMAILS?: string
  /** 角色包编写器线上地址，用于「打开编写器」按钮 */
  readonly VITE_PACK_EDITOR_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
