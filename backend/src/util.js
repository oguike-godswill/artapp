const mongoose = require('mongoose');

class HttpError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

const asyncH = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

function validate(schema, data) {
  const r = schema.safeParse(data ?? {});
  if (!r.success) {
    const first = r.error.issues[0];
    throw new HttpError(400, first?.message || 'Invalid input', r.error.issues);
  }
  return r.data;
}

function objectId(id) {
  if (!mongoose.isValidObjectId(id)) throw new HttpError(404, 'Not found');
  return id;
}

module.exports = { HttpError, asyncH, validate, objectId };
