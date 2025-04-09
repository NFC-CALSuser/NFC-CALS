const crypto = require('crypto');
const fetch = require('node-fetch');

let SECRET_KEY = null;

async function initializeSecretKey() {
  try {
    const response = await fetch('https://nfc-calsuser.github.io/NFC-CALS/NFC-Server/data/APIs.json');
    const data = await response.json();
    SECRET_KEY = data.hmac_key;
  } catch (error) {
    console.error('Failed to initialize secret key:', error);
    throw error;
  }
}

function createHMAC(password) {
  if (!SECRET_KEY) throw new Error('Secret key not initialized');
  return crypto.createHmac('sha256', SECRET_KEY)
    .update(password)
    .digest('hex');
}

function verifyPassword(inputPassword, storedPassword) {
  const hmac = createHMAC(inputPassword);
  return hmac === storedPassword;
}

function hashPassword(password) {
  return createHMAC(password);
}

// Hash all passwords in files
const fs = require('fs');
const path = require('path');

function hashAllPasswords() {
    // Hash students passwords
    const studentsPath = path.join(__dirname, '../data/students.json');
    const studentsData = JSON.parse(fs.readFileSync(studentsPath, 'utf8'));
    studentsData.students.forEach(student => {
        student.password = hashPassword(student.password);
    });
    fs.writeFileSync(studentsPath, JSON.stringify(studentsData, null, 2));

    // Hash instructors passwords
    const instructorsPath = path.join(__dirname, '../data/instructors.json');
    const instructorsData = JSON.parse(fs.readFileSync(instructorsPath, 'utf8'));
    instructorsData.instructors.forEach(instructor => {
        instructor.password = hashPassword(instructor.password);
    });
    fs.writeFileSync(instructorsPath, JSON.stringify(instructorsData, null, 2));

    console.log('All passwords have been hashed successfully!');
}

module.exports = { createHMAC, verifyPassword, hashPassword, hashAllPasswords, initializeSecretKey };
