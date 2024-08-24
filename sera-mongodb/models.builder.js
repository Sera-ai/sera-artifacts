const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema(
  {
    nodes: [{
      required: true,
      type: mongoose.Types.ObjectId,
      ref: "builder_nodes",
    }],
    edges: [{
      required: true,
      type: mongoose.Types.ObjectId,
      ref: "builder_edges",
    }],
    enabled: {
      required: false,
      type: Boolean,
    },
  },
  { collection: "builder_inventory", strict: false }
);

module.exports = seraConnection.model("builder_inventory", dataSchema);