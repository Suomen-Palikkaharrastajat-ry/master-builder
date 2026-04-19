// Toggle annotator when toolbar icon is clicked
browser.browserAction.onClicked.addListener((tab) => {
  browser.tabs.sendMessage(tab.id, { type: "TOGGLE" });
});

async function sendToActiveTab(message) {
  const tabs = await browser.tabs.query({ active: true, currentWindow: true });
  const activeTab = tabs[0];
  if (!activeTab || typeof activeTab.id !== "number") return;
  return browser.tabs.sendMessage(activeTab.id, message);
}

function dataUrlToBlob(dataUrl) {
  const match = /^data:([^;,]*)(;base64)?,(.*)$/.exec(String(dataUrl || ""));
  if (!match) throw new Error("Invalid data URL");

  const mimeType = match[1] || "application/octet-stream";
  const isBase64 = Boolean(match[2]);
  const payload = match[3] || "";

  let bytesString;
  if (isBase64) {
    bytesString = atob(payload);
  } else {
    bytesString = decodeURIComponent(payload);
  }

  const bytes = new Uint8Array(bytesString.length);
  for (let i = 0; i < bytesString.length; i += 1) {
    bytes[i] = bytesString.charCodeAt(i);
  }
  return new Blob([bytes], { type: mimeType });
}

async function resolveDownloadUrl(message) {
  if (message.blob instanceof Blob) {
    return { url: URL.createObjectURL(message.blob), revoke: true };
  }
  if (typeof message.dataUrl === "string" && message.dataUrl.startsWith("data:")) {
    const blob = dataUrlToBlob(message.dataUrl);
    return { url: URL.createObjectURL(blob), revoke: true };
  }
  if (typeof message.dataUrl === "string") {
    return { url: message.dataUrl, revoke: false };
  }
  throw new Error("No downloadable payload provided");
}

browser.commands.onCommand.addListener((command) => {
  if (command === "capture-visible-shortcut") {
    void sendToActiveTab({ type: "SHORTCUT_CAPTURE_VISIBLE" });
  } else if (command === "capture-fullpage-shortcut") {
    void sendToActiveTab({ type: "SHORTCUT_CAPTURE_FULLPAGE" });
  }
});

// Handle messages from content script
browser.runtime.onMessage.addListener((message, sender) => {
  if (message.type === "CAPTURE") {
    return browser.tabs.captureVisibleTab(sender.tab.windowId, { format: "png" });
  }

  if (message.type === "SAVE_FILE") {
    return resolveDownloadUrl(message).then(({ url, revoke }) => {
      return browser.downloads.download({
        url,
        filename: message.filename || `download-${Date.now()}`,
        saveAs: message.saveAs !== false,
        conflictAction: "uniquify",
      }).finally(() => {
        if (revoke) {
          setTimeout(() => {
            try { URL.revokeObjectURL(url); } catch (_) {}
          }, 60_000);
        }
      });
    });
  }
});
