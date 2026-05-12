"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = errorHandler;
function errorHandler(err, _req, res, _next) {
    console.error('Error:', err.message);
    // Prisma unique constraint violation
    if (err.code === 'P2002') {
        res.status(409).json({ error: 'A record with this value already exists' });
        return;
    }
    // Prisma record not found
    if (err.code === 'P2025') {
        res.status(404).json({ error: 'Record not found' });
        return;
    }
    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        res.status(401).json({ error: 'Invalid token' });
        return;
    }
    if (err.name === 'TokenExpiredError') {
        res.status(401).json({ error: 'Token expired' });
        return;
    }
    const statusCode = err.statusCode || 500;
    const message = statusCode === 500 ? 'Internal server error' : err.message;
    res.status(statusCode).json({ error: message });
}
//# sourceMappingURL=errorHandler.js.map