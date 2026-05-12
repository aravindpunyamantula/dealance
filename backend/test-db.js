const tls = require('tls');
const net = require('net');

const socket = new net.Socket();
socket.connect(5432, 'database-1.cm7g22sws8hs.us-east-1.rds.amazonaws.com', () => {
    console.log('Connected');
    socket.write(Buffer.from([0, 0, 0, 8, 4, 210, 22, 47])); // SSLRequest
});

socket.on('data', (data) => {
    console.log('Received: ', data);
    socket.destroy();
});

socket.on('error', (err) => {
    console.log('Error: ', err.message);
});
