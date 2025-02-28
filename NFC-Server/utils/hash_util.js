const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// This should be stored in environment variables in production
const SECRET_KEY = '4a9c5c2e89f340c399a6a3f3928021f48920a206e09c4336b580bacbb34e3034';

function createHMAC(password) {
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

module.exports = { createHMAC, verifyPassword, hashPassword, hashAllPasswords };
