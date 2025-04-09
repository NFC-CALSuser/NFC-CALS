const { validationResult, check } = require('express-validator');

const validateAttendanceData = [
  check('id').trim().notEmpty().isString(),
  check('course_id').trim().matches(/^[A-Z]{3,4}\d{3}$/),
  check('classroom').trim().matches(/^[A-Z]-\d{3}$/),
  check('instructor_id').trim().isString(),
  check('students_ids').isArray(),
  check('date').isISO8601(),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  }
];

module.exports = { validateAttendanceData };