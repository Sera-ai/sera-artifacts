const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema(
  {
    event: {
      required: true,
      type: String,
    },
    type: {
      required: true,
      type: String,
    },
    data: {
      required: true,
      type: Object,
    },
    description: {
      required: false,
      type: String,
    },
  },
  { collection: "event_struc" }
);

module.exports = seraConnection.model("event_struc", dataSchema);
