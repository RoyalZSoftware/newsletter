import { spawnSync } from 'child_process';

export class NewsletterError extends Error {
    constructor(message) {
        super(message)
    }
}

/**
 * @typedef {Object} NewsletterClientOptions
 * @property {string} bin the binary path
 * @property {boolean} useSudo
 * @property {string} baseDir
 */

const DEFAULT_OPTIONS = {
    bin: 'newsletter',
    useSudo: false,
    baseDir: '' // unset: take default or from .env variables
};

/**
 * @param {NewsletterClientOptions} options 
 */
export const makeClient = (options) => {
    const mergedOptions = {...DEFAULT_OPTIONS, ...options};
    /**
     * @param {string} cmd
     * @param {string[]} params
     */
    const call = (cmd, ...params) => {
        const prompt = [mergedOptions.useSudo ? "sudo" : "", mergedOptions.bin, cmd, ...params].join(' ');
        const result = spawnSync(prompt, {shell: true, env: {
            BASE_DIR: mergedOptions.baseDir
        }});
        if (result.error) {
            throw result.error;
        }
        if (result.status == 1) {
            throw new NewsletterError(result.stdout?.toString());
        }
        if (result.status != 0) {
            throw new Error(result.stderr);
        }
        return result.stdout.toString();
    }

    return {
        subscribe: (email) => call('subscribe', email),
        confirm: (email, code) => call('confirm', email, code),
        unsubscribe: (email) => call('unsubscribe', email),
        list: () => call('list'),
    };
}