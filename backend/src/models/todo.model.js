const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../db/database');

const SORTABLE_COLUMNS = new Set(['created_at', 'updated_at', 'due_date', 'priority', 'title']);
const UPDATABLE_FIELDS = new Set(['title', 'description', 'completed', 'priority', 'due_date', 'tags']);

function now() {
  return new Date().toISOString();
}

function deserialize(row) {
  if (!row) return null;
  return {
    ...row,
    completed: row.completed === 1,
    tags: JSON.parse(row.tags),
  };
}

const TodoModel = {
  create({ title, description = '', priority = 'medium', due_date = null, tags = [] }) {
    const db = getDb();
    const id = uuidv4();
    const timestamp = now();

    db.prepare(`
      INSERT INTO todos (id, title, description, completed, priority, due_date, tags, created_at, updated_at)
      VALUES (?, ?, ?, 0, ?, ?, ?, ?, ?)
    `).run(id, title, description, priority, due_date, JSON.stringify(tags), timestamp, timestamp);

    return this.findById(id);
  },

  findAll({ completed, priority, search, sortBy = 'created_at', order = 'desc', limit = 50, offset = 0 } = {}) {
    const db = getDb();
    const where = [];
    const params = [];

    if (completed !== undefined) {
      where.push('completed = ?');
      params.push(completed ? 1 : 0);
    }
    if (priority !== undefined) {
      where.push('priority = ?');
      params.push(priority);
    }
    if (search) {
      where.push('(title LIKE ? OR description LIKE ?)');
      const term = `%${search}%`;
      params.push(term, term);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const sortColumn = SORTABLE_COLUMNS.has(sortBy) ? sortBy : 'created_at';
    const sortOrder = String(order).toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const total = db
      .prepare(`SELECT COUNT(*) AS count FROM todos ${whereClause}`)
      .get(...params).count;

    const rows = db
      .prepare(`
        SELECT * FROM todos
        ${whereClause}
        ORDER BY ${sortColumn} ${sortOrder}
        LIMIT ? OFFSET ?
      `)
      .all(...params, limit, offset);

    return {
      data: rows.map(deserialize),
      total,
      limit,
      offset,
    };
  },

  findById(id) {
    const db = getDb();
    const row = db.prepare('SELECT * FROM todos WHERE id = ?').get(id);
    return deserialize(row);
  },

  update(id, fields) {
    const db = getDb();
    const sets = [];
    const params = [];

    for (const [key, value] of Object.entries(fields)) {
      if (!UPDATABLE_FIELDS.has(key)) continue;
      sets.push(`${key} = ?`);
      if (key === 'completed') {
        params.push(value ? 1 : 0);
      } else if (key === 'tags') {
        params.push(JSON.stringify(value));
      } else {
        params.push(value);
      }
    }

    if (sets.length === 0) return this.findById(id);

    sets.push('updated_at = ?');
    params.push(now(), id);

    const result = db
      .prepare(`UPDATE todos SET ${sets.join(', ')} WHERE id = ?`)
      .run(...params);

    if (result.changes === 0) return null;
    return this.findById(id);
  },

  delete(id) {
    const db = getDb();
    const result = db.prepare('DELETE FROM todos WHERE id = ?').run(id);
    return result.changes > 0;
  },

  bulkComplete(ids, completed) {
    const db = getDb();
    if (!Array.isArray(ids) || ids.length === 0) return 0;

    const placeholders = ids.map(() => '?').join(',');
    const result = db
      .prepare(`UPDATE todos SET completed = ?, updated_at = ? WHERE id IN (${placeholders})`)
      .run(completed ? 1 : 0, now(), ...ids);

    return result.changes;
  },

  bulkDelete(ids) {
    const db = getDb();
    if (!Array.isArray(ids) || ids.length === 0) return 0;

    const placeholders = ids.map(() => '?').join(',');
    const result = db
      .prepare(`DELETE FROM todos WHERE id IN (${placeholders})`)
      .run(...ids);

    return result.changes;
  },

  stats() {
    const db = getDb();
    const total = db.prepare('SELECT COUNT(*) AS count FROM todos').get().count;
    const completed = db.prepare('SELECT COUNT(*) AS count FROM todos WHERE completed = 1').get().count;
    const pending = total - completed;
    const overdue = db
      .prepare(`
        SELECT COUNT(*) AS count FROM todos
        WHERE completed = 0 AND due_date IS NOT NULL AND due_date < ?
      `)
      .get(now()).count;

    const byPriorityRows = db
      .prepare('SELECT priority, COUNT(*) AS count FROM todos GROUP BY priority')
      .all();

    const by_priority = { low: 0, medium: 0, high: 0 };
    for (const row of byPriorityRows) {
      by_priority[row.priority] = row.count;
    }

    return { total, completed, pending, overdue, by_priority };
  },
};

module.exports = TodoModel;
