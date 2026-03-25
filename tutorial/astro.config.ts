import tutorialkit from '@tutorialkit-rb/astro';
import { defineConfig } from 'astro/config';
import remarkRailsPathLinks from './src/plugins/remarkRailsPathLinks';

export default defineConfig({
  devToolbar: {
    enabled: false,
  },
  vite: {
    server: {
      watch: {
        ignored: ['**/ruby-wasm/**'],
      },
    },
    build: {
      rollupOptions: {
        external: [/ruby-wasm/],
      },
    },
  },
  integrations: [
    tutorialkit({
      components: {
        TopBar: './src/components/TopBar.astro',
        HeadTags: './src/components/HeadTags.astro',
      },
      defaultRoutes: true,
    }),
  ],
  markdown: {
    remarkPlugins: [remarkRailsPathLinks],
  },
});
