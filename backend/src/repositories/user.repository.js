const db = require('../infrastructure/database');
const User = require('../models/user.model');

class UserRepository {
  async findByEmail(email) {
    const res = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (res.rows.length === 0) return null;
    
    return new User(res.rows[0]);
  }

  async create(user) {
    const query = `
      INSERT INTO users (name, email, password, role)
      VALUES ($1, $2, $3, $4) RETURNING *
    `;
    const values = [user.name, user.email, user.password, user.role];
    const res = await db.query(query, values);
    
    return new User(res.rows[0]);
  }
}

module.exports = new UserRepository();