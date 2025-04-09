const crypto = require('crypto');
const fs = require('fs');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
const path = require('path');

async function encryptFiles() {
  try {
    // Get encryption key from API
    const response = await fetch('https://nfc-calsuser.github.io/NFC-CALS/NFC-Server/data/APIs.json');
    const config = await response.json();
    
    // Convert hex string to Buffer and ensure 16 bytes length for AES-128
    const ENCRYPTION_KEY = Buffer.from(config.encryption_key, 'hex').slice(0, 16);

    // Define file paths
    const dataDir = path.join(__dirname, '..', 'data');
    const studentsPath = path.join(dataDir, 'students.json');
    const instructorsPath = path.join(dataDir, 'instructors.json');

    // Encrypt students.json
    const studentsData = fs.readFileSync(studentsPath, 'utf8');
    const studentsIv = crypto.randomBytes(16);
    const studentsCipher = crypto.createCipheriv('aes-128-cbc', ENCRYPTION_KEY, studentsIv);
    let encryptedStudents = studentsCipher.update(studentsData, 'utf8', 'base64');
    encryptedStudents += studentsCipher.final('base64');

    fs.writeFileSync(path.join(dataDir, 'students_encrypted.json'), JSON.stringify({
      iv: studentsIv.toString('base64'),
      data: encryptedStudents
    }));

    // Encrypt instructors.json
    const instructorsData = fs.readFileSync(instructorsPath, 'utf8');
    const instructorsIv = crypto.randomBytes(16);
    const instructorsCipher = crypto.createCipheriv('aes-128-cbc', ENCRYPTION_KEY, instructorsIv);
    let encryptedInstructors = instructorsCipher.update(instructorsData, 'utf8', 'base64');
    encryptedInstructors += instructorsCipher.final('base64');

    fs.writeFileSync(path.join(dataDir, 'instructors_encrypted.json'), JSON.stringify({
      iv: instructorsIv.toString('base64'),
      data: encryptedInstructors
    }));

    console.log('Files encrypted successfully!');
  } catch (error) {
    console.error('Encryption failed:', error);
  }
}

// Run encryption
encryptFiles();