const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function encryptFiles() {
  try {
    // Get encryption key from API
    const response = await fetch('https://nfc-calsuser.github.io/NFC-CALS/NFC-Server/data/APIs.json');
    const config = await response.json();
    
    // Convert hex to buffer for AES-128
    const ENCRYPTION_KEY = Buffer.from(config.encryption_key, 'hex');
    console.log('Key length:', ENCRYPTION_KEY.length, 'bytes');

    const dataDir = path.join(__dirname, '..', 'data');

    // Function to encrypt data
    const encryptData = (data) => {
      // Generate random IV
      const iv = crypto.randomBytes(16);
      
      // Create cipher with AES-128-CBC
      const cipher = crypto.createCipheriv('aes-128-cbc', ENCRYPTION_KEY.slice(0, 16), iv);
      
      // Encrypt data
      let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'base64');
      encrypted += cipher.final('base64');

      return {
        iv: iv.toString('base64'),
        data: encrypted
      };
    };

    // Encrypt students.json
    console.log('Encrypting students.json...');
    const studentsData = JSON.parse(fs.readFileSync(path.join(dataDir, 'students.json'), 'utf8'));
    const encryptedStudents = encryptData(studentsData);
    fs.writeFileSync(
      path.join(dataDir, 'students_encrypted.json'),
      JSON.stringify(encryptedStudents, null, 2)
    );

    // Encrypt instructors.json
    console.log('Encrypting instructors.json...');
    const instructorsData = JSON.parse(fs.readFileSync(path.join(dataDir, 'instructors.json'), 'utf8'));
    const encryptedInstructors = encryptData(instructorsData);
    fs.writeFileSync(
      path.join(dataDir, 'instructors_encrypted.json'),
      JSON.stringify(encryptedInstructors, null, 2)
    );

    console.log('Files encrypted successfully!');
  } catch (error) {
    console.error('Encryption failed:', error);
  }
}

encryptFiles();