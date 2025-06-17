# Newsletter

Stupidly simple newsletter manager.

Its written in bash and PERL.

## Capabilities
- fully file system based
- Subscribe email [with code verification]
- Unsubscribe
- Templating for newsletter issues
- Log for sent email issues
- Works with bash error codes and prints errors

## Integration
Use whatever tech stack you want, as long as you can execute a OS command, you're ready to go.

## API
```bash
$ ./bin/newsletter subscribe <email>
30f91 # this is the code
$ ./bin/newsletter confirm <email> <code>
$ echo $?
0 # worked
$ ./bin/newsletter unsubscribe <email>
$ echo $?
0 # worked
```
