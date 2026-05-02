const UserRepository = require('../repositories/user.repository');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

class AuthService {
  async register(userData) {
    const hashedPassword = await bcrypt.hash(userData.password, 10);
    
    const user = await UserRepository.create({
      ...userData,
      password: hashedPassword
    });

    return this.generateToken(user);
  }

  generateToken(user) {
    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    return { token, user: { name: user.name, role: user.role } };
  }
}

module.exports = new AuthService();