// import { getRandomReferrer, getRandomRecruiter, insertJobToSheet } from './backend.js';
// use them as needed

// monitor.js
if (!document.getElementById('ngl-floating-icon')) {
  const icon = document.createElement('img');
  icon.src = chrome.runtime.getURL('icons/icon48.png');
  icon.id = 'ngl-floating-icon';
  icon.style.position = 'fixed';
  icon.style.bottom = '20px';
  icon.style.left = '20px';
  icon.style.width = '48px';
  icon.style.height = '48px';
  icon.style.zIndex = '10000';
  icon.style.cursor = 'pointer';
  icon.style.borderRadius = '50%';
  icon.style.boxShadow = '0 4px 12px rgba(0,0,0,0.3)';
  icon.title = 'Track this job';

  icon.onclick = () => {
//   const companyGuess = window.location.hostname.split('.')[0];
  createFloatingForm();
  };

  document.body.appendChild(icon);
}

function createFloatingForm(companyGuess = '') {
  // Avoid duplicate forms
  if (document.getElementById('ngl-job-form')) return;

  const form = document.createElement('div');
  form.id = 'ngl-job-form';
  form.innerHTML = `
    <style>
      #ngl-job-form {
        position: fixed;
        bottom: 80px;
        left: 20px;
        background: white;
        border: 1px solid #ccc;
        border-radius: 8px;
        padding: 16px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        max-width: 300px;
        width: 90%;
        z-index: 1000000;
        box-sizing: border-box;
        overflow: hidden;
        }

        #ngl-job-form input,
        #ngl-job-form button {
        width: 100%;
        margin-top: 8px;
        padding: 6px 10px;
        font-size: 14px;
        box-sizing: border-box;
        }
      #ngl-job-form button {
        background-color: #2980b9;
        color: white;
        border: none;
        cursor: pointer;
        border-radius: 4px;
      }
      #ngl-job-form-close {
        position: absolute;
        top: 6px;
        right: 10px;
        cursor: pointer;
        color: #888;
      }
    </style>
    <div id="ngl-job-form-close">✖</div>
    <h4 style="margin: 0 0 10px 0;">Quick Add Job</h4>
    <input type="text" id="ngl-company" placeholder="Company" value="${companyGuess}">
    <input type="text" id="ngl-link" placeholder="Job Link" value="${window.location.href}">
    <button id="ngl-submit">Add Job</button>
  `;

  document.body.appendChild(form);

  document.getElementById('ngl-job-form-close').onclick = () => {
    form.remove();
  };

  document.getElementById('ngl-submit').onclick = async () => {
    const company = document.getElementById('ngl-company').value.trim();
    const link = document.getElementById('ngl-link').value.trim();
    const today = new Date();
    const date = `${today.getMonth() + 1}/${today.getDate()}/${today.getFullYear()}`;
    if (!company || !link) {
      alert("Company and link required!");
      return;
    }

    chrome.runtime.sendMessage(
        {
            type: 'addJob',
            company,
            link
        },
        (response) => {
            if (chrome.runtime.lastError) {
            console.error("Runtime error:", chrome.runtime.lastError.message);
            alert("Extension runtime error: " + chrome.runtime.lastError.message);
            return;
            }

            if (!response) {
            console.error("No response received from background script.");
            alert("No response from background.");
            return;
            }

            if (response.success) {
            alert("Job added to Sheet!");
            } else {
            alert("Failed to add job: " + response.error);
            }
        }
    );

  };
}
