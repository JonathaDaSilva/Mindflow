const express = require('express');
require('dotenv').config();
const authRoutes = require('./src/routes/auth.routes');

class AppController {
  constructor() {
    this.express = express();
    this.middlewares();
    this.routes();
  }

  middlewares() {
    this.express.use(express.json());
  }

  routes() {
    this.express.use('/auth', authRoutes);

    this.express.get('/health', (req, res) => {
      return res.json({ status: 'MindFlow API is running' });
    });
  }
}

module.exports = new AppController().express;