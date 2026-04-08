import { createRouter, createWebHistory } from 'vue-router'

export default createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: () => import('../views/HomeView.vue') },
    {
      path: '/packs',
      component: () => import('../views/packs/PacksLayout.vue'),
      children: [
        { path: '', redirect: { name: 'packs-full' } },
        { path: 'full', name: 'packs-full', component: () => import('../views/packs/PacksFullView.vue') },
        { path: 'compose', name: 'packs-compose', component: () => import('../views/packs/PacksComposeView.vue') },
        { path: 'part/:kind', name: 'packs-part', component: () => import('../views/packs/PacksPartView.vue'), props: true },
        { path: ':id', name: 'pack-detail', component: () => import('../views/PackDetailView.vue'), props: true },
      ],
    },
    { path: '/plugins', name: 'plugins', component: () => import('../views/PluginsView.vue') },
    { path: '/modules', name: 'modules', component: () => import('../views/ModulesView.vue') },
    { path: '/me', name: 'personal', component: () => import('../views/PersonalView.vue') },
    { path: '/manage', name: 'manage', component: () => import('../views/ManageView.vue') },
    { path: '/admin', name: 'admin', component: () => import('../views/AdminView.vue') },
    { path: '/search', name: 'search', component: () => import('../views/SearchView.vue') },
  ],
  scrollBehavior() {
    return { top: 0 }
  },
})
