const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema(
  {
    sera_config: {
      required: true,
      type: Object,
    },
  },
  { collection: "sera_dns" }
);

module.exports = seraConnection.model("sera_dns", dataSchema);
