const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema({
  host_id: {
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: "sera_hosts",
  },
  builder_id: {
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: "builder_inventory",
  },
  endpoint: {
    required: true,
    type: String,
  },
  method: {
    required: true,
    type: String,
  },
  attributes: {
    required: true,
    type: Array
  }
});

module.exports = seraConnection.model("sera_endpoints", dataSchema);
