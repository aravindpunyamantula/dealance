const net = require('net');

const client = new net.Socket();

client.connect(5432, 'database-1.cm7g22sws8hs.us-east-1.rds.amazonaws.com', function() {
    console.log('Connected');
    
    // PostgreSQL StartupMessage (fake, just to trigger a response)
    // Send 8 bytes: Length (00 00 00 08) + Protocol (04 d2 16 2f)
    const buf = Buffer.from([0x00, 0x00, 0x00, 0x08, 0x04, 0xd2, 0x16, 0x2f]);
    client.write(buf);
});

client.on('data', function(data) {
    console.log('Received: ' + data.toString('hex'));
    client.destroy(); // kill client after server's response
});

client.on('close', function() {
    console.log('Connection closed');
});

client.on('error', function(err) {
    console.error('Connection error:', err);
});
