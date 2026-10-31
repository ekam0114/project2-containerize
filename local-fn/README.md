# local-fn

AWS SAM Hello World function scaffold for local invocation.

From this directory, run:

```bash
sam local invoke HelloWorldFunction
sam local invoke HelloWorldFunction -e events/event.json
```

The local invocation uses Docker to run a Lambda-compatible runtime container. It does not require deploying the function to AWS.
