import { useStore } from '@nanostores/react';
import type { PreviewInfo } from '@tutorialkit-rb/runtime';
import { useEffect } from 'react';
import tutorialStore from 'tutorialkit:store';

const ensureRailsServerStarted = async (preview: PreviewInfo) => {
  if (preview.ready) {
    return;
  }

  const terminalConfig = tutorialStore.terminalConfig.get();
  const terminal = terminalConfig.panels.find((panel) => panel.type === 'terminal');

  if (!terminal || !terminal.process) {
    return;
  }

  terminal.input(`bin/rails s\n`);

  await new Promise<void>((resolve, reject) => {
    const tid = setTimeout(() => {
      clearInterval(tick);
      reject();
    }, 10000);

    const tick = setInterval(() => {
      if (preview.ready) {
        clearInterval(tick);
        clearTimeout(tid);
        resolve();
      }
    }, 200);
  });
};

export default function RailsPathLinkHandler() {
  const previews = useStore(tutorialStore.previews);

  useEffect(() => {
    async function handleClick(event: MouseEvent) {
      const target = event.target as HTMLElement;
      const link = target.closest('.rails-path-link');

      if (link) {
        event.preventDefault();

        const railsPath = link.getAttribute('data-rails-path');

        if (railsPath) {
          tutorialStore.setSelectedFile(`/workspace/store/${railsPath}`);
        }

        return;
      }

      if (target.tagName === 'A') {
        const linkTarget = target as HTMLAnchorElement;

        if (linkTarget.href.startsWith('http://localhost:3000')) {
          event.preventDefault();

          const railsPreview = previews.find((pr) => pr.port === 3000);

          if (!railsPreview) {
            return;
          }

          try {
            await ensureRailsServerStarted(railsPreview);
          } catch (error) {
            console.error('failed to start Rails server', e);
            return;
          }

          const input = document.querySelector(
            'input[type="text"][name="tutorialkit-preview-navigation"]',
          ) as HTMLInputElement;

          if (!input) {
            return;
          }

          const newPath = linkTarget.href.replace('http://localhost:3000/', '');

          input.value = newPath;

          const ev = new KeyboardEvent('keydown', {
            key: 'Enter',
            code: 'Enter',
            keyCode: 13,
            bubbles: true,
            cancelable: true,
          });
          input.dispatchEvent(ev);
        }
      }
    }

    document.addEventListener('click', handleClick);

    return () => {
      document.removeEventListener('click', handleClick);
    };
  }, [previews]);

  return null;
}
