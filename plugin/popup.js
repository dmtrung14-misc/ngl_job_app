import { getRandomReferrer, getRandomRecruiter, insertJobToSheet } from './backend.js';
document.addEventListener('DOMContentLoaded', () => {
  const companyInput = document.getElementById('company');
  const linkInput = document.getElementById('link');
  const jobTypeInput = document.getElementById('jobType');
  const dateInput = document.getElementById('date');

  // Prefill link and date
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    linkInput.value = tabs[0]?.url || '';
  });
  const today = new Date();
  dateInput.value = `${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}`;

  // Add Job button handler
  document.getElementById('addJobButton').addEventListener('click', async () => {
    const company = companyInput.value.trim();
    const link = linkInput.value.trim();
    const jobType = jobTypeInput.value;
    const date = dateInput.value;

    if (!company || !link) {
      alert('Company and Link are required.');
      return;
    }

    try {
      const [referrer, recruiter] = await Promise.all([
        getRandomReferrer(company),
        getRandomRecruiter(company),
      ]);

      await insertJobToSheet(company, link, referrer, recruiter, date, jobType);
      alert('Job added to Sheet!');
      companyInput.value = '';
    } catch (e) {
      console.error(e);
      alert('Error adding job: ' + e.message);
    }
  });

  // View switch to report form
  document.getElementById('goReport').addEventListener('click', () => {
    document.getElementById('mainView').style.display = 'none';
    document.getElementById('reportView').style.display = 'block';
  });

  document.getElementById('backBtn').addEventListener('click', () => {
    document.getElementById('reportView').style.display = 'none';
    document.getElementById('mainView').style.display = 'block';
  });
});