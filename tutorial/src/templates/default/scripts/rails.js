import fs from 'fs';
import { join } from 'path';
import { spawn } from 'child_process';

const railsRootDir = new URL("../workspace/store", import.meta.url).pathname;
const railsPath = join(railsRootDir, 'bin/rails');

const waitBinRails = async () => {
  const timeoutMs = 30000;
  const startTime = Date.now();

  for (; ;) {
    if (Date.now() - startTime > timeoutMs) {
      console.error('Timeout waiting for rails script');
      throw 'Timed out to wait for bin/rails';
    }

    const found = await new Promise((resolve) => {
      fs.access(railsPath, fs.constants.X_OK, (err) => {
        if (err) {
          resolve(false)
          return;
        }

        resolve(true)
      })
    });

    if (found) return;

    await new Promise((resolve) => setTimeout(resolve, 500));
  }
}

await waitBinRails();

const railsProcess = spawn("rails", process.argv.slice(2), {
  stdio: 'inherit',
  cwd: railsRootDir,
  env: {
    PATH: "/home/tutorial/bin:/bin:/usr/bin:/usr/local/bin"
  }
});

railsProcess.on('error', (err) => {
  console.error('Failed to start rails script:', err);
  process.exit(1);
});

railsProcess.on('close', (code) => {
  process.exit(code);
});
