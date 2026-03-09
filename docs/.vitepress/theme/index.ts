// https://vitepress.dev/guide/custom-theme
import { h } from 'vue'
import type { Theme } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import AvailableSince from './components/AvailableSince.vue'
import LandingLayout from './layouts/LandingLayout.vue'
import './style.css'

export default {
  extends: DefaultTheme,
  Layout: () => {
    return h(DefaultTheme.Layout, null, {
      // https://vitepress.dev/guide/extending-default-theme#layout-slots
    })
  },
  enhanceApp({ app, router, siteData }) {
    app.component('AvailableSince', AvailableSince)
    app.component('LandingLayout', LandingLayout)
  }
} satisfies Theme
