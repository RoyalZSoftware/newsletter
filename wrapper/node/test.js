import {makeClient} from './index.js'
import { join, dirname } from 'path';
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))

const client = makeClient({
    bin: join(__dirname, '..', '..', 'bin', 'newsletter'),
    baseDir: '/tmp/test1',
})

const code = client.subscribe('panov@royalzsoftware.de');

client.confirm('panov@royalzsoftware.de', code)

console.log(client.list())
