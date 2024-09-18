const mongoose = require("mongoose");
const { seraConnection } = require("./db.handler.cjs");

const dataSchema = new mongoose.Schema(
  {
    event: {
      required: true,
      type: String,
    },
    eventId: {
      required: false,
      type: String,
    },
    type: {
      required: true,
      type: String,
    },
    srcIp: {
      required: false,
      type: String,
    },
    ts: {
      required: false,
      type: Number,
    },
    data: {
      required: true,
      type: Object,
      default: {}, // Set an empty object as the default value
    },
  },
  { collection: "sera_events", strict: false }
);

dataSchema.pre("save", async function (next) {
  const doc = this;

  // Automatically set the current timestamp for the 'ts' field
  if (!doc.ts) {
    doc.ts = Date.now();
  }

  if (!doc.srcIp) {
    doc.srcIp = "127.0.0.1";
  }

  // Auto-increment the eventId
  if (!doc.eventId) {
    try {
      const latestDoc = await seraConnection.model("sera_events").findOne().sort({ ts: -1 }).exec();
      let newEventId = 1;

      if (latestDoc && latestDoc.eventId) {
        const latestEventId = parseInt(latestDoc.eventId.split('-')[1]);
        newEventId = latestEventId + 1;
      }

      doc.eventId = `EVT-${newEventId.toString().padStart(4, "0")}`;
      next();
    } catch (error) {
      next(error);
    }
  } else {
    next();
  }
});

module.exports = seraConnection.model("sera_events", dataSchema);