import fs from 'node:fs/promises';

const statusFilePath = new URL("../.status", import.meta.url).pathname;

async function checkIfFileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch (error) {
    return false;
  }
}

export async function wait() {
  if (process.env.READY_CHECK === "off") {
    return;
  }

  let tid;
  let timeoutId;
  let noticeShown;

  const checkAndResolve = async (resolve) => {
    const exists = await checkIfFileExists(statusFilePath);
    if (exists) {
      clearTimeout(timeoutId);
      resolve();
    } else {
      if (!noticeShown) {
        console.log('Waiting for Ruby VM to become ready... (see the Setup Logs tab)')
        noticeShown = true;
      }
      tid = setTimeout(function () { checkAndResolve(resolve) }, 1000)
    }
  };

  await new Promise((resolve, reject) => {
    checkAndResolve(resolve)
    timeoutId = setTimeout(function() {
      clearTimeout(tid)
      reject(new Error("Timed out waiting for Ruby VM to become ready"))
    }, 30000)
  })
}

if (process.argv[2]) {
  const command = process.argv[2];

  if (command === "off") {
    const exists = await checkIfFileExists(statusFilePath);
    if (exists) {
      fs.rm(statusFilePath);
    }
  }

  if (command === "on") {
    const exists = await checkIfFileExists(statusFilePath);
    if (!exists) {
      fs.writeFile(statusFilePath, "");
    }
  }
}
