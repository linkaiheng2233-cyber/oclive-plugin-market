/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL?: string
  readonly VITE_SUPABASE_ANON_KEY?: string
  readonly VITE_ADMIN_EMAILS?: string
  /** 角色包编写器线上地址，用于「打开编写器」按钮 */
  readonly VITE_PACK_EDITOR_URL?: string
  /** 与 oclivenewnew 客户端默认插件索引同源，用于站内展示「索引 JSON」链接 */
  readonly VITE_PLUGIN_INDEX_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
