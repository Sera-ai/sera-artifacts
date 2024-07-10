// db.js
const mongoose = require('mongoose');

const connectToDatabase = (uri, dbName) => {
  return mongoose.createConnection(uri, { dbName });
};

const nginxConnection = connectToDatabase(process.env.DB_HOST, 'nginx');
const seraConnection = connectToDatabase(process.env.DB_HOST, 'Sera');

module.exports = {
  nginxConnection,
  seraConnection
};
