const fs = require('fs');
const bcrypt = require('bcrypt');
const path = require('path');

const saltRounds = 10;

async function hashPasswords() {
    // Handle students
    const studentsPath = path.join(__dirname, '../data/students.json');
    const studentsData = JSON.parse(fs.readFileSync(studentsPath, 'utf8'));
    
    for (const student of studentsData.students) {
        student.password = await bcrypt.hash(student.password, saltRounds);
    }
    
    fs.writeFileSync(studentsPath, JSON.stringify(studentsData, null, 2));

    // Handle instructors
    const instructorsPath = path.join(__dirname, '../data/instructors.json');
    const instructorsData = JSON.parse(fs.readFileSync(instructorsPath, 'utf8'));
    
    for (const instructor of instructorsData.instructors) {
        instructor.password = await bcrypt.hash(instructor.password, saltRounds);
    }
    
    fs.writeFileSync(instructorsPath, JSON.stringify(instructorsData, null, 2));
    
    console.log('All passwords have been hashed with bcrypt successfully!');
}

hashPasswords().catch(console.error);
