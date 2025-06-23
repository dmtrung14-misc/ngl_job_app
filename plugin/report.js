document.addEventListener('DOMContentLoaded', () => {
  const repCompanyInput = document.getElementById('repCompany');
  const repNameInput = document.getElementById('repName');
  const repContactInput = document.getElementById('repContact');
  const repTypeSelect = document.getElementById('repType');

  document.getElementById('reportButton').addEventListener('click', async () => {
    const company = repCompanyInput.value.trim();
    const name = repNameInput.value.trim();
    const contact = repContactInput.value.trim();
    const type = repTypeSelect.value;

    if (!company || !name || !contact || !type) {
      alert('Please fill out all fields.');
      return;
    }

    const databaseURL = 'https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com';
    const path = `/companies/${encodeURIComponent(company)}/${type}`;
    const url = `${databaseURL}${path}.json`;

    const entry = { name, contact };

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(entry),
      });

      if (!response.ok) throw new Error('Failed to submit report');

      alert('Report submitted!');
      repCompanyInput.value = '';
      repNameInput.value = '';
      repContactInput.value = '';
    } catch (err) {
      console.error('Report error:', err);
      alert('Error submitting report: ' + err.message);
    }
  });
});
