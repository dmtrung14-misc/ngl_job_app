// Firebase REST: get random referrer
export async function getRandomReferrer(company) {
  const databaseURL = 'https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com';
  const url = `${databaseURL}/companies/${encodeURIComponent(company)}/referrers.json`;

  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to fetch referrers');
    const data = await response.json();
    if (!data) return '';

    const values = Object.values(data);
    const randomRef = values[Math.floor(Math.random() * values.length)];
    return randomRef.name + " : " + (randomRef.contact ? randomRef.contact : "No contact") || '';
  } catch (err) {
    console.error('Error fetching random referrer:', err);
    return '';
  }
}

// Firebase REST: get random recruiter
export async function getRandomRecruiter(company) {
  const databaseURL = 'https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com';
  const url = `${databaseURL}/companies/${encodeURIComponent(company)}/recruiters.json`;

  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to fetch recruiters');
    const data = await response.json();
    if (!data) return '';

    const values = Object.values(data);
    const randomRec = values[Math.floor(Math.random() * values.length)];
    return randomRec.name + " : "  + (randomRec.contact ? randomRec.contact : "No contact") || '';
  } catch (err) {
    console.error('Error fetching random recruiter:', err);
    return '';
  }
}

// Add row to Google Sheet
export async function insertJobToSheet(company, link, referrer, recruiter, date, jobType = 'newgrad') {
  const token = await new Promise((resolve, reject) => {
    chrome.identity.getAuthToken({ interactive: true }, (token) => {
      if (chrome.runtime.lastError || !token) {
        reject(new Error(chrome.runtime.lastError?.message || 'Auth failed'));
      } else {
        resolve(token);
      }
    });
  });

  const headers = {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json',
  };

  const spreadsheetId = SPREADSHEET_ID || '1wm5K1d9ScRhvLNYbSXhQuJjFnGr0jPrL0eJfn2bMYKM';
  
  // Determine sheet ID based on job type
  // sheetId 0 = first tab (New Grad), sheetId 1 = second tab (Intern)
  const sheetId = jobType === 'intern' ? 2033324761 : 0;

  const body = {
    requests: [
      {
        insertDimension: {
          range: { sheetId: sheetId, dimension: 'ROWS', startIndex: 1, endIndex: 2 },
          inheritFromBefore: false,
        },
      },
      {
        updateCells: {
          start: { sheetId: sheetId, rowIndex: 1, columnIndex: 0 },
          rows: [{
            values: [
              { userEnteredValue: { stringValue: company } },
              { userEnteredValue: { stringValue: link } },
              { userEnteredValue: { stringValue: referrer } },
              { userEnteredValue: { stringValue: recruiter } },
              { userEnteredValue: { stringValue: date } },
              { userEnteredValue: { stringValue: 'No Action' } },
            ],
          }],
          fields: 'userEnteredValue',
        },
      },
    ],
  };

  const res = await fetch(
    `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}:batchUpdate`,
    { method: 'POST', headers, body: JSON.stringify(body) }
  );

  if (!res.ok) {
    const errorData = await res.json();
    throw new Error(`Sheets API error: ${errorData.error.message}`);
  }
}
