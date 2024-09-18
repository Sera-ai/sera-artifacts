const mongoose = require('mongoose');
const { seraConnection } = require('./db.handler.cjs');

const dataSchema = new mongoose.Schema(
    {
        name: {
            required: false,
            type: String
        },
        slug: {
            required: false,
            type: String
        },
        type: {
            required: false,
            type: String
        },
        hostname: {
            required: false,
            type: String
        },
        image: {
            required: false,
            type: mongoose.Types.ObjectId,
            ref: 'fs.files'
        },
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
            type: Boolean
        }
    },
    { collection: "builder_integrations", strict: false }
)

module.exports = seraConnection.model('builder_integrations', dataSchema)