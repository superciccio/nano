// @ts-check
import { themes as prismThemes } from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Nano',
  tagline: 'Minimalist Atomic State Management for Flutter',
  favicon: 'img/favicon.ico',

  url: 'https://superciccio.github.io',
  baseUrl: '/nano/',

  organizationName: 'superciccio',
  projectName: 'nano',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          editUrl:
            'https://github.com/superciccio/nano/tree/main/website/',
        },
        blog: false, // Disable blog for now to keep it simple
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/docusaurus-social-card.jpg', // You might want to update this later
      navbar: {
        title: 'Nano',
        logo: {
          alt: 'Nano Logo',
          src: 'img/logo.svg', // Default logo for now
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: 'Guide',
          },
          {
            to: '/docs/examples',
            label: 'Examples',
            position: 'left',
          },
          // Link to the generated API docs (Needs to be in static/api)
          {
            href: 'pathname:///api/index.html',
            label: 'API Reference',
            position: 'left',
          },
          {
            href: 'https://github.com/superciccio/nano',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Get Started',
                to: '/docs/intro',
              },
              {
                label: 'Examples',
                to: '/docs/examples',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'GitHub Issues',
                href: 'https://github.com/superciccio/nano/issues',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/superciccio/nano',
              },
              {
                label: 'Pub.dev',
                href: 'https://pub.dev/packages/nano',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Nano. Built with Docusaurus.`,
      },
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['dart'], // Enable Dart syntax highlighting
      },
    }),
};

export default config;
