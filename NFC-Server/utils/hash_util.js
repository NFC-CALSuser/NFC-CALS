const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
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

module.exports = { hashPassword, hashAllPasswords };
