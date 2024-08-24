const mongoose = require('mongoose');
const { seraConnection } = require('./db.handler');

const dataSchema = new mongoose.Schema(
    {
        servers: {
            required: true,
            type: Array,
        },
        paths: {
            required: true,
            type: Object,
            default: {}, // Set an empty object as the default value
        },
    },
    { collection: "oas_inventory", strict: false }
);
dataSchema.set('versionKey', false);

module.exports = seraConnection.model('oas_inventory', dataSchema)