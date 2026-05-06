const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const TodoModel = require('../models/todo.model');

const router = express.Router();

const PRIORITIES = ['low', 'medium', 'high'];
const SORTABLE = ['created_at', 'updated_at', 'due_date', 'priority', 'title'];

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
    });
  }
  next();
}

router.get('/stats', (req, res) => {
  try {
    const stats = TodoModel.stats();
    res.json({ success: true, data: stats });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get(
  '/',
  [
    query('completed').optional().isBoolean().toBoolean(),
    query('priority').optional().isIn(PRIORITIES),
    query('search').optional().isString(),
    query('sortBy').optional().isIn(SORTABLE),
    query('order').optional().isIn(['asc', 'desc']),
    query('limit').optional().isInt({ min: 1, max: 200 }).toInt(),
    query('offset').optional().isInt({ min: 0 }).toInt(),
  ],
  validate,
  (req, res) => {
    try {
      const result = TodoModel.findAll(req.query);
      res.json({ success: true, data: result });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.get(
  '/:id',
  [param('id').isString().notEmpty()],
  validate,
  (req, res) => {
    try {
      const todo = TodoModel.findById(req.params.id);
      if (!todo) {
        return res.status(404).json({ success: false, message: 'Todo not found' });
      }
      res.json({ success: true, data: todo });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.post(
  '/',
  [
    body('title').isString().trim().notEmpty().withMessage('title is required'),
    body('description').optional().isString(),
    body('priority').optional().isIn(PRIORITIES),
    body('due_date').optional({ nullable: true }).isISO8601(),
    body('tags').optional().isArray(),
    body('tags.*').isString(),
  ],
  validate,
  (req, res) => {
    try {
      const todo = TodoModel.create(req.body);
      res.status(201).json({ success: true, data: todo });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.patch(
  '/:id',
  [
    param('id').isString().notEmpty(),
    body('title').optional().isString().trim().notEmpty(),
    body('description').optional().isString(),
    body('completed').optional().isBoolean(),
    body('priority').optional().isIn(PRIORITIES),
    body('due_date').optional({ nullable: true }).isISO8601(),
    body('tags').optional().isArray(),
    body('tags.*').isString(),
  ],
  validate,
  (req, res) => {
    try {
      const todo = TodoModel.update(req.params.id, req.body);
      if (!todo) {
        return res.status(404).json({ success: false, message: 'Todo not found' });
      }
      res.json({ success: true, data: todo });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.delete(
  '/:id',
  [param('id').isString().notEmpty()],
  validate,
  (req, res) => {
    try {
      const ok = TodoModel.delete(req.params.id);
      if (!ok) {
        return res.status(404).json({ success: false, message: 'Todo not found' });
      }
      res.json({ success: true, data: { id: req.params.id } });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.post(
  '/bulk/complete',
  [
    body('ids').isArray({ min: 1 }),
    body('ids.*').isString().notEmpty(),
    body('completed').isBoolean(),
  ],
  validate,
  (req, res) => {
    try {
      const changed = TodoModel.bulkComplete(req.body.ids, req.body.completed);
      res.json({ success: true, data: { changed } });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.post(
  '/bulk/delete',
  [
    body('ids').isArray({ min: 1 }),
    body('ids.*').isString().notEmpty(),
  ],
  validate,
  (req, res) => {
    try {
      const changed = TodoModel.bulkDelete(req.body.ids);
      res.json({ success: true, data: { changed } });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

module.exports = router;
