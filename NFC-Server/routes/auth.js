const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const { hashPassword } = require('../utils/hash_util');

// Load data from JSON files
const studentsData = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/students.json'), 'utf8'));
const instructorsData = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/instructors.json'), 'utf8'));

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    const hashedInputPassword = hashPassword(password); // Hash the input password
    
    // For students
    const student = studentsData.students.find(s => s.email === email);
    if (student && student.password === hashedInputPassword) {
        return res.json({ 
            success: true,
            user: {
                id: student.id,
                name: student.name,
                email: student.email,
                role: 'student'
            }
        });
    }

    // For instructors
    const instructor = instructorsData.instructors.find(i => i.email === email);
    if (instructor && instructor.password === hashedInputPassword) {
        return res.json({
            success: true,
            user: {
                id: instructor.id,
                name: instructor.name,
                email: instructor.email,
                role: 'instructor'
            }
        });
    }

    res.status(401).json({ success: false, message: 'Invalid email or password' });
});

module.exports = router;
