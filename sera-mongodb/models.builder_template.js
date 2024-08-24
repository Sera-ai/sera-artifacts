const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema(
  {
    nodes: {
      required: true,
      type: Array,
    },
    edges: {
      required: true,
      type: Array,
    },
    enabled: {
      required: false,
      type: Boolean,
    },
  },
  { collection: "builder_template", strict: false }
);

module.exports = seraConnection.model("builder_template", dataSchema);