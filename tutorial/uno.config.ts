import { defineConfig } from '@tutorialkit-rb/theme';

export default defineConfig({
  // required for TutorialKit monorepo development mode
  content: {
    pipeline: {
      include: '**',
    },
  },
});
