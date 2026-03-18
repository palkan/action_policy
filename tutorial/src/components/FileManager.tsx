import { useStore } from '@nanostores/react';
import type { WebContainer } from '@webcontainer/api';
import { useRef, useEffect } from 'react';
import { webcontainer } from 'tutorialkit:core';
import tutorialStore from 'tutorialkit:store';

const VERSIONED_WASM_URL = `/ruby.wasm`;
const GEMFILE_HASH_URL = `/ruby.wasm.hash`;
const WC_WASM_LOG_PATH = `/ruby.wasm.log.txt`;
const WC_WASM_PATH = `/ruby.wasm`;

export function FileManager() {
  const lessonLoaded = useStore(tutorialStore.lessonFullyLoaded);
  const files = useStore(tutorialStore.files);
  const processedFiles = useRef(new Set<string>());
  const wasmCached = useRef(false);

  async function fetchGemfileHash(): Promise<string> {
    try {
      console.log(`Fetching Gemfile hash from ${GEMFILE_HASH_URL}...`);

      const response = await fetch(GEMFILE_HASH_URL);

      if (!response.ok) {
        console.warn(`Failed to fetch ruby.wasm.hash: ${response.status}`);
        return 'default';
      }

      const hash = (await response.text()).trim();
      console.log(`Fetched Gemfile hash: ${hash}`);

      return hash;
    } catch (error) {
      console.warn('Failed to fetch Gemfile hash, using default version:', error);
      return 'default';
    }
  }

  function getVersionedCacheFileName(gemfileLockHash: string): string {
    return `ruby-${gemfileLockHash}.wasm`;
  }

  async function chmodx(wc: WebContainer, path: string) {
    const process = await wc.spawn('chmod', ['+x', path]);

    const exitCode = await process.exit;

    if (exitCode !== 0) {
      console.error(`failed to chmox +x ${path}: `, exitCode);
    } else {
      console.log(`updated permissions for: ${path}`);
    }
  }

  async function fetchCachedWasmFile(cacheFileName: string): Promise<Uint8Array | null> {
    try {
      const opfsRoot = await navigator.storage.getDirectory();
      const fileHandle = await opfsRoot.getFileHandle(cacheFileName);
      const file = await fileHandle.getFile();
      console.log(`Found cached Ruby WASM: ${cacheFileName}`);

      return new Uint8Array(await file.arrayBuffer());
    } catch {
      return null;
    }
  }

  async function persistWasmFile(wasmData: Uint8Array, cacheFileName: string): Promise<void> {
    try {
      const opfsRoot = await navigator.storage.getDirectory();
      const fileHandle = await opfsRoot.getFileHandle(cacheFileName, { create: true });
      const writable = await fileHandle.createWritable();
      await writable.write(wasmData);
      await writable.close();
      console.log(`Ruby WASM file ${cacheFileName} cached`);
    } catch (error) {
      console.error('Failed to persist Ruby WASM:', error);
    }
  }

  async function cleanupOldCacheFiles(currentCacheFileName: string): Promise<void> {
    try {
      const opfsRoot = await navigator.storage.getDirectory();

      for await (const [name] of opfsRoot.entries()) {
        if (
          ((name.startsWith('ruby-') && name.endsWith('.wasm')) || name === 'ruby.wasm') &&
          name !== currentCacheFileName
        ) {
          console.log(`Removing old cached Ruby WASM: ${name}`);
          await opfsRoot.removeEntry(name);
        }
      }
    } catch (error) {
      console.warn('Failed to cleanup old cache files:', error);
    }
  }

  async function cacheWasmFile(wc: WebContainer, cacheFileName: string): Promise<void> {
    console.log(`Dowloading WASM file ${VERSIONED_WASM_URL}...`);

    try {
      const wasm = await fetch(VERSIONED_WASM_URL);
      await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: downloaded');

      const wasmData = new Uint8Array(await wasm.arrayBuffer());
      await persistWasmFile(wasmData, cacheFileName);
      await cleanupOldCacheFiles(cacheFileName);
      await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: cached');
      await wc.fs.writeFile(WC_WASM_PATH, wasmData);
    } catch {
      await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: error');
    }
  }

  useEffect(() => {
    if (!lessonLoaded) {
      return;
    }

    if (!files) {
      return;
    }

    (async () => {
      const wc = await webcontainer;

      Object.entries(files).forEach(([_, fd]) => {
        const dir = fd.path.split('/').filter(Boolean).slice(-2, -1)[0];

        if (dir === 'bin' && !processedFiles.current.has(fd.path)) {
          processedFiles.current = new Set([...processedFiles.current, fd.path]);
          chmodx(wc, '/home/tutorial' + fd.path);
        }
      });

      if (!wasmCached.current) {
        await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: init');

        const gemfileLockHash = await fetchGemfileHash();
        const cacheFileName = getVersionedCacheFileName(gemfileLockHash);
        console.log(`Using cache file: ${cacheFileName} (hash: ${gemfileLockHash})`);

        const cachedWasm = await fetchCachedWasmFile(cacheFileName);

        if (cachedWasm) {
          await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: load from cache');
          await wc.fs.writeFile(WC_WASM_PATH, cachedWasm);
          await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: done');
          console.log(`Ruby WASM ${cacheFileName} loaded from cache`);
          wasmCached.current = true;
        } else {
          await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: download');
          await cacheWasmFile(wc, cacheFileName);
          await wc.fs.writeFile(WC_WASM_LOG_PATH, 'status: done');
          wasmCached.current = true;
        }
      }
    })();

    return () => {};
  }, [lessonLoaded, files]);

  return null;
}
