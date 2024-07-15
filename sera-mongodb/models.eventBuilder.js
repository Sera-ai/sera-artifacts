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
    slug: {
      required: true,
      type: String,
    },
    enabled: {
      required: true,
      type: Boolean,
    },
    name: {
      required: true,
      type: String,
    },
    type: {
      required: true,
      type: String,
    },
  },
  { collection: "builder_events" }
);

module.exports = seraConnection.model("builder_events", dataSchema);
