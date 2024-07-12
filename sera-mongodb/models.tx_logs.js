const mongoose = require("mongoose");
const { nginxConnection } = require("./db.handler");

const dataSchema = new mongoose.Schema(
    {
        hostname: {
            required: true,
            type: String
        },
        path: {
            required: true,
            type: String
        },
        response_time: {
            required: true,
            type: Number
        },
        ts: {
            required: true,
            type: Number
        },
        ts_breakdown: {
            required: false,
            type: Object,
        },
        ssl_analytics: {
            required: false,
            type: Object,
        },
        session_analytics: {
            required: false,
            type: Object,
        },
        method: {
            required: true,
            type: String
        },
        request: {
            required: false,
            type: Object,
        },
        response: {
            required: false,
            type: Object,
        },
    },
    { collection: "tx_logs" }
);

module.exports = nginxConnection.model("tx_logs", dataSchema);
