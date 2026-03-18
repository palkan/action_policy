import { useStore } from '@nanostores/react';
import type { WebContainerProcess } from '@webcontainer/api';
import { useEffect, useState } from 'react';
import tutorialStore from 'tutorialkit:store';

type ShellConfig = Partial<{
  workdir: string;
}>;

let observedProcess: WebContainerProcess | undefined = undefined;
let currWorkdir = '';

export const ShellConfigurator: React.FC = () => {
  const boot = useStore(tutorialStore.bootStatus);
  const storeRef = useStore(tutorialStore.ref);
  const terminalConfig = useStore(tutorialStore.terminalConfig);
  const lessonLoaded = useStore(tutorialStore.lessonFullyLoaded);
  const [state, set] = useState(0);

  useEffect(() => {
    const unlisten = tutorialStore.terminalConfig.listen(() => {
      set(state + 1);
    });
    return unlisten;
  }, [terminalConfig]);

  const lesson = tutorialStore.lesson;
  const terminal = terminalConfig.panels.find((panel) => panel.type === 'terminal');

  useEffect(() => {
    if (boot !== 'booted') {
      return;
    }

    if (!lessonLoaded) {
      return;
    }

    if (!lesson) {
      return;
    }

    if (!terminal) {
      return;
    }

    const conf = lesson?.data?.custom?.shell as ShellConfig;

    if (!conf) {
      return;
    }

    const { workdir } = conf;

    if (!workdir) {
      return;
    }

    if (currWorkdir === workdir) {
      return;
    }

    currWorkdir = workdir;

    const checkProcess = () => {
      if (terminal.process || observedProcess) {
        if (!observedProcess) {
          observedProcess = terminal.process;
        }

        terminal.input(`cd /home/tutorial${workdir} && clear\n`);

        return true;
      }

      return false;
    };

    // Check immediately
    if (checkProcess()) {
      return;
    }

    // Set up interval to wait for process
    const interval = setInterval(() => {
      if (checkProcess()) {
        clearInterval(interval);
      }
    }, 100);

    return () => clearInterval(interval);
  }, [boot, terminalConfig, storeRef, lessonLoaded]);

  return null;
};
