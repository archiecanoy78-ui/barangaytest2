const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;

// MOCK IN-MEMORY DATABASE FOR DEMONSTRATION
const blotterDb = {
    'ERP-2026-B041': {
        refId: 'ERP-2026-B041',
        complainant: 'Maria Santos',
        respondent: 'Juan Dela Cruz',
        category: 'Neighborhood Dispute / Noise',
        dateLogged: 'Oct 26, 2026 - 10:14 PM',
        status: 'In Progress - Tanod Dispatched',
        step: 3, // 1: Submitted, 2: Verification, 3: Tanod Dispatched, 4: Lupon, 5: Resolved
        assignedOfficer: 'Bgy. Tanod Patrol Team #4 (Sgt. Mateo)',
        details: 'Loud videoke complaint after 10:00 PM curfew. Patrol unit dispatched to issue verbal warning.'
    },
    'ERP-2026-A098': {
        refId: 'ERP-2026-A098',
        complainant: 'Ricardo Diaz',
        respondent: 'Unknown',
        category: 'Minor Theft (Bicycle)',
        dateLogged: 'Oct 24, 2026 - 04:30 PM',
        status: 'Case Resolved',
        step: 5,
        assignedOfficer: 'Bgy. Tanod Alcantara',
        details: 'Stolen bicycle recovered via CCTV monitoring near Plaza. Amicably settled.'
    },
    'ERP-2026-B101': {
        refId: 'ERP-2026-B101',
        complainant: 'Elena Gomez',
        respondent: 'Rafael Mercado',
        category: 'Property Boundary Dispute',
        dateLogged: 'Oct 22, 2026 - 02:15 PM',
        status: 'Lupon Hearing Scheduled',
        step: 4,
        assignedOfficer: 'Lupon Chairperson Reyes',
        details: 'Dispute regarding fence construction. 1st Mediation hearing scheduled on Nov 1, 2026 at 2:00 PM.'
    }
};

const documentRequests = [];

const server = http.createServer((req, res) => {
    // Enable CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
    const pathname = parsedUrl.pathname;

    // API ENDPOINTS
    if (pathname.startsWith('/api/blotter/')) {
        const refId = pathname.split('/api/blotter/')[1].toUpperCase();
        if (blotterDb[refId]) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, data: blotterDb[refId] }));
        } else {
            // Return generated mock data for unknown IDs
            const mockEntry = {
                refId: refId,
                complainant: 'Verified Resident / Confidential',
                respondent: 'Under Field Investigation',
                category: 'Community Blotter Log',
                dateLogged: new Date().toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' }),
                status: 'Under Desk Review',
                step: 2,
                assignedOfficer: 'Barangay Secretary Desk Officer',
                details: 'Report logged in the official e-governance system. Case assigned to field patrol officer.'
            };
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, data: mockEntry }));
        }
        return;
    }

    if (pathname === '/api/incidents' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            try {
                const payload = JSON.parse(body || '{}');
                const refId = 'ERP-2026-B' + Math.floor(100 + Math.random() * 900);
                const newRecord = {
                    refId: refId,
                    complainant: payload.reporter || 'Verified Resident',
                    respondent: 'Under Review',
                    category: payload.category || 'General Incident',
                    dateLogged: new Date().toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' }),
                    status: 'In Progress - Tanod Dispatched',
                    step: 3,
                    assignedOfficer: 'Bgy. Tanod Quick Response Unit',
                    details: payload.description || 'Report filed online via E-Reportyan Portal.'
                };
                blotterDb[refId] = newRecord;
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, refId: refId, record: newRecord }));
            } catch (err) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, message: 'Invalid payload' }));
            }
        });
        return;
    }

    if (pathname === '/api/clearances' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            try {
                const payload = JSON.parse(body || '{}');
                const reqId = 'REQ-2026-CLR-' + Math.floor(1000 + Math.random() * 9000);
                const record = {
                    reqId: reqId,
                    applicant: payload.applicant || 'Juan D. Dela Cruz',
                    docType: payload.docType || 'Barangay Clearance',
                    purpose: payload.purpose || 'Employment',
                    status: 'Approved - Ready for QR Download',
                    dateSubmitted: new Date().toLocaleDateString()
                };
                documentRequests.push(record);
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, reqId: reqId, record: record }));
            } catch (err) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, message: 'Invalid request' }));
            }
        });
        return;
    }

    // STATIC FILE SERVER
    let filePath = path.join(__dirname, pathname === '/' ? 'index.html' : pathname);
    fs.readFile(filePath, (err, content) => {
        if (err) {
            fs.readFile(path.join(__dirname, 'index.html'), (err2, fallback) => {
                if (err2) {
                    res.writeHead(500);
                    res.end('Server Error');
                } else {
                    res.writeHead(200, { 'Content-Type': 'text/html' });
                    res.end(fallback);
                }
            });
        } else {
            let ext = path.extname(filePath);
            let contentType = 'text/html';
            if (ext === '.css') contentType = 'text/css';
            if (ext === '.js') contentType = 'text/javascript';
            if (ext === '.json') contentType = 'application/json';
            if (ext === '.png') contentType = 'image/png';
            if (ext === '.jpg' || ext === '.jpeg') contentType = 'image/jpeg';
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(PORT, () => {
    console.log(`====================================================`);
    console.log(`  BARANGAY E-REPORTYAN PUBLIC SERVICE PORTAL`);
    console.log(`  Server running at http://localhost:${PORT}/`);
    console.log(`====================================================`);
});
