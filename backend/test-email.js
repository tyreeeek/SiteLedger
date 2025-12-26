require('dotenv').config();
const { sendWorkerInvite } = require('./src/utils/emailService');

console.log('🧪 Testing email to safia.jawazkhan@nrcs.net...\n');

sendWorkerInvite('safia.jawazkhan@nrcs.net', 'Safia', 'Zia', 'TestPass123!')
    .then(result => {
        console.log('\n✅ EMAIL SENT SUCCESSFULLY!');
        console.log('Result:', result);
        console.log('\n📬 Check safia.jawazkhan@nrcs.net inbox!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ EMAIL FAILED:');
        console.error('Error:', error.message);
        console.error('\nFull error:', error);
        process.exit(1);
    });
