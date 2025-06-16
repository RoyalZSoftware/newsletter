#!/usr/bin/env node

const {spawnSync} = require('child_process');
const { join } = require('path')

const result = spawnSync('bin/newsletter subscribe panov@royalzsoftware.de', {
    cwd: join(__dirname, '..'),
    shell: true,
});

console.log(result.status);
console.log(result.stdout.toString());
