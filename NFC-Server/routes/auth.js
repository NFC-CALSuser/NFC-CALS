const bcrypt = require('bcrypt');
const express = require('express');
const router = express.Router();
const students = require('./students');
const instructors = require('./instructors');
const { hashPassword } = require('../utils/hash_util');

// ...existing code...

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    const hashedPassword = hashPassword(password);
    
    // For students
    const student = students.find(s => s.email === email);
    if (student && student.password === hashedPassword) {
        // ...existing login success code...
    }

    // For instructors
    const instructor = instructors.find(i => i.email === email);
    if (instructor && instructor.password === hashedPassword) {
        // ...existing login success code...
    }

    // ...existing error handling code...
});

module.exports = router;
