const sanitize = require('mongo-sanitize');

const sanitizeInput = (req, res, next) => {
  req.body = sanitize(req.body);
  req.params = sanitize(req.params);
  req.query = sanitize(req.query);
  next();
};

module.exports = sanitizeInput;