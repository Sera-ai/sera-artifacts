const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler.cjs");

const dataSchema = new mongoose.Schema(
    {},
    { collection: 'fs.files' } // Link this schema to the fs.files collection
  );

module.exports = seraConnection.model("fs.files", dataSchema);
