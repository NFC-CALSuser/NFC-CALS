const bcrypt = require('bcrypt');
const express = require('express');
const router = express.Router();
const students = require('./students');
const instructors = require('./instructors');
const { verifyPassword } = require('../utils/hash_util');

// ...existing code...

router.post('/login', (req, res) => {
    const { email, password } = req.body;
    
    // For students
    const student = students.find(s => s.email === email);
    if (student && verifyPassword(password, student.password)) {
        // ...existing login success code...
    }

    // For instructors
    const instructor = instructors.find(i => i.email === email);
    if (instructor && verifyPassword(password, instructor.password)) {
        // ...existing login success code...
    }

    // ...existing error handling code...
});

module.exports = router;
