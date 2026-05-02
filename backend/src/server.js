const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  =========================================
  MindFlow Server is running on port ${PORT}
  Context: Psychologist App
  Docker Container: Active
  =========================================
  `);
});