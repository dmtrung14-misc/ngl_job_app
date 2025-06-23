import keywordList from './keywords.json' assert { type: 'json' };
import { insertJobToSheet, getRandomReferrer, getRandomRecruiter } from './backend.js'; // or move to sheetUtils.js

console.log("✅ Background script loaded!");

chrome.runtime.onInstalled.addListener(() => {
  // Initialize lastReminderDate to yesterday on install
  const yesterday = new Date(Date.now() - 864e5);
  const yesterdayStr = `${yesterday.getMonth()+1}/${yesterday.getDate()}/${yesterday.getFullYear()}`;
  chrome.storage.local.set({ lastReminderDate: yesterdayStr });
});

chrome.runtime.onStartup.addListener(async () => {
  // Check if we already showed reminder today
  const today = new Date();
  const todayStr = `${today.getMonth()+1}/${today.getDate()}/${today.getFullYear()}`;
  const { lastReminderDate } = await chrome.storage.local.get('lastReminderDate');
  if (lastReminderDate === todayStr) return;  // already shown today

  // Fetch sheet data to compute counts
  const token = await new Promise((resolve, reject) => {
    chrome.identity.getAuthToken({interactive: false}, (t) => {
      if (chrome.runtime.lastError) reject(chrome.runtime.lastError);
      else resolve(t);
    });
  });
  const headers = { 'Authorization': 'Bearer ' + token };
  const spreadsheetId = SPREADSHEET_ID || '1wm5K1d9ScRhvLNYbSXhQuJjFnGr0jPrL0eJfn2bMYKM';  // <-- set your Sheet ID
  // Get all entries from columns E (Date) and F (Status)
  const range = 'Sheet1!E2:F'; 
  const resp = await fetch(`https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/${range}`, { headers });
  const data = await resp.json();
  const values = data.values || [];

  // Count “No Action” and entries from yesterday
  const yesterday = new Date(today.getTime() - 864e5);
  const yesterdayStr = `${yesterday.getMonth()+1}/${yesterday.getDate()}/${yesterday.getFullYear()}`;
  let noActionCount = 0, yesterdayCount = 0;
  for (const row of values) {
    const date = row[0];       // column E
    const status = row[1];     // column F
    if (status === 'No Action') noActionCount++;
    if (date === yesterdayStr) yesterdayCount++;
  }

  // Show notification (Chrome Notifications API)
  chrome.notifications.create('', {
    type: 'basic',
    iconUrl: 'icons/icon128.png',
    title: 'NGL Job Tracker Reminder',
    message: `No Action: ${noActionCount}\nAdded Yesterday: ${yesterdayCount}`,
    buttons: [{ title: 'Open Sheet' }]
  });

  // Handle notification button click
  chrome.notifications.onButtonClicked.addListener((notifId, btnIdx) => {
    if (btnIdx === 0) {
      chrome.tabs.create({ url: `https://docs.google.com/spreadsheets/d/${spreadsheetId}` });
    }
  });

  // Update lastReminderDate
  chrome.storage.local.set({ lastReminderDate: todayStr });
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    console.log(tabId, changeInfo.status, tab.url)
    const matched = keywordList.some(keyword => tab.url.toLowerCase().includes(keyword.toLowerCase()));
    if (matched) {
      console.log('Injecting banner for', tab.url);
      chrome.scripting.executeScript({
        target: { tabId },
        files: ['banner.js']
      }).catch(err => console.error('Script injection failed:', err));
    }
  }
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'addJob') {
    (async () => {
      try {
        const { company, link } = message;
        const referrer = await getRandomReferrer(company);
        const recruiter = await getRandomRecruiter(company);
        const date = new Date().toLocaleDateString();
        await insertJobToSheet(company, link, referrer, recruiter, date);
        sendResponse({ success: true });
      } catch (error) {
        console.error("Job insertion failed:", error);
        sendResponse({ success: false, error: error.message });
      }
    })();

    // Important to keep the message channel open
    return true;
  }
});

setInterval(() => {
  console.log("💡 Service worker waiting for signal");
}, 100000);

