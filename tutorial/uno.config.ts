import { defineConfig } from '@tutorialkit-rb/theme';

export default defineConfig({
  theme: {
    colors: {
      accent: {
        50: '#EFF6FF',
        100: '#E5F0FF',
        200: '#B6D4FF',
        300: '#75B5FF',
        400: '#4DA6FF',
        500: '#0E7EF1',
        600: '#0F4D8A',
        700: '#0C3F72',
        800: '#09325A',
        900: '#072848',
        950: '#041A30',
      },
    },
  },
  content: {
    pipeline: {
      include: '**',
    },
  },
});
