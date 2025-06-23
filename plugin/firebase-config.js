// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getDatabase } from "firebase/database";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDhmgMkG-DXAH5G8d3CkW6RxStDYw2xtq8",
  authDomain: "ngl-job-board-d5bd8.firebaseapp.com",
  databaseURL: "https://ngl-job-board-d5bd8-default-rtdb.firebaseio.com",
  projectId: "ngl-job-board-d5bd8",
  storageBucket: "ngl-job-board-d5bd8.firebasestorage.app",
  messagingSenderId: "1065581044209",
  appId: "1:1065581044209:web:b93e78023af56e6349e450",
  measurementId: "G-1LT1KVXDJS"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const database = getDatabase(app);

export { database };