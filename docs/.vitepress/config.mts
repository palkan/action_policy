import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "Action Policy",
  description: "Authorization framework for Ruby and Rails applications",
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#0F4D8A' }],
    ['meta', { property: 'og:title', content: 'Action Policy' }],
    ['meta', { property: 'og:description', content: 'Authorization framework for Ruby/Rails applications' }],
    ['meta', { property: 'og:image', content: 'https://actionpolicy.evilmartians.io/assets/images/banner2023.png' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:site', content: '@palkan_tula' }],
    ['meta', { name: 'twitter:creator', content: '@palkan_tula' }],
    ['meta', { name: 'keywords', content: 'ruby, rails, authorization, open-source' }],
  ],
  themeConfig: {
    logo: '/assets/images/logo-bare.svg',

    nav: [
      { text: 'Guide', link: '/guide/', activeMatch: '/guide/' },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/' },
            { text: 'Quick Start', link: '/guide/quick_start' },
            { text: 'Writing Policies', link: '/guide/writing_policies' },
            { text: 'Rails Integration', link: '/guide/rails' },
            { text: 'Non-Rails Usage', link: '/guide/non_rails' },
            { text: 'Testing', link: '/guide/testing' },
          ]
        },
        {
          text: 'Features',
          items: [
            { text: 'Authorization Behaviour', link: '/guide/behaviour' },
            { text: 'Policy Lookup', link: '/guide/lookup_chain' },
            { text: 'Authorization Context', link: '/guide/authorization_context' },
            { text: 'Aliases', link: '/guide/aliases' },
            { text: 'Pre-Checks', link: '/guide/pre_checks' },
            { text: 'Scoping', link: '/guide/scoping' },
            { text: 'Caching', link: '/guide/caching' },
            { text: 'Namespaces', link: '/guide/namespaces' },
            { text: 'Failure Reasons', link: '/guide/reasons' },
            { text: 'Instrumentation', link: '/guide/instrumentation' },
            { text: 'I18n Support', link: '/guide/i18n' },
            { text: 'Debugging', link: '/guide/debugging' },
          ]
        },
        {
          text: 'Integrations',
          items: [
            { text: 'GraphQL', link: '/guide/graphql' },
            { text: 'Graphiti', link: 'https://github.com/shrimple-tech/action_policy-graphiti' },
          ]
        },
        {
          text: 'Tips & Tricks',
          items: [
            { text: 'From Pundit to Action Policy', link: '/guide/pundit_migration' },
            { text: 'Dealing with Decorators', link: '/guide/decorators' },
          ]
        },
        {
          text: 'Customize',
          items: [
            { text: 'Base Policy', link: '/guide/custom_policy' },
            { text: 'Lookup Chain', link: '/guide/custom_lookup_chain' },
          ]
        },
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/palkan/action_policy' }
    ],

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/palkan/action_policy/edit/master/docs/:path'
    },
  }
})
