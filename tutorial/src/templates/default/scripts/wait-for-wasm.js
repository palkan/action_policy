#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';

const __dirname = path.dirname(new URL(import.meta.url).pathname);
const TARGET_DIR = path.join(__dirname, '../node_modules/@ruby/wasm-wasi/dist');
const TARGET_FILE = path.join(TARGET_DIR, 'ruby.wasm');

const WASM_FILE = path.join(__dirname, '../ruby.wasm');
const LOG_FILE = path.join(__dirname, '../ruby.wasm.log.txt');

async function checkIfFileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch (error) {
    console.log(`✗ Failed to access ${filePath}: ${error.message}`);
    return false;
  }
}

async function moveFile(src, dest) {
  try {
    await fs.mkdir(path.dirname(dest), { recursive: true });
    await fs.rename(src, dest);
    console.log(`✓ Moved ${src} to ${dest}`);

    return true;
  } catch (error) {
    console.error(`✗ Failed to move ${src} to ${dest}:`, error.message);
    return false;
  }
}

let lastStatus;

async function checkWasmLoaded() {
  if (await checkIfFileExists(TARGET_FILE)) {
    return true;
  }

  if (!(await checkIfFileExists(LOG_FILE))) {
    return false;
  }

  lastStatus = await fs.readFile(LOG_FILE, { encoding: 'utf8' });

  console.log(`[ruby.wasm] ${lastStatus}`);

  if (lastStatus === 'status: done') {
    await moveFile(WASM_FILE, TARGET_FILE);
    return true;
  }

  return false;
}

async function main() {
  await new Promise((resolve, reject) => {
    const startTime = Date.now();
    const STATUS_TIMEOUT = 30000; // 30 seconds to start
    const OVERALL_TIMEOUT = 300000; // 5 minutes total

    async function checkAndScheduleNext() {
      try {
        if (await checkWasmLoaded()) {
          console.log(`[ruby.wasm] ready`);
          resolve();

          return;
        }

        const elapsed = Date.now() - startTime;

        // check if we've exceeded the status timeout and still no status
        if (elapsed > STATUS_TIMEOUT && !lastStatus) {
          reject(new Error('Timeout waiting for wasm download to start'));
          return;
        }

        // check if we've exceeded the overall timeout
        if (elapsed > OVERALL_TIMEOUT) {
          reject(new Error('Timeout waiting for wasm to load'));
          return;
        }

        // schedule next check
        setTimeout(checkAndScheduleNext, 1000);
      } catch (error) {
        reject(error);
      }
    }

    // start the checking process
    checkAndScheduleNext();
  });
}

main().catch((error) => {
  console.error('Preinstall script failed:', error);
  process.exit(1);
});
