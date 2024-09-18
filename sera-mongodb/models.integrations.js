const mongoose = require('mongoose');
const { seraConnection } = require('./db.handler');

const dataSchema = new mongoose.Schema({
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
    image: {
        required: false,
        type: mongoose.Types.ObjectId, // Reference to the ObjectId in the fs.files collection
        ref: 'fs.files'  // Reference the GridFS files collection
    },
    hostname: {
        required: false,
        type: String
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
}, { collection: "builder_integrations", minimize: false })

module.exports = seraConnection.model('builder_integrations', dataSchema)