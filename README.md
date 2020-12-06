# mojolicious-two-servers-sample
Sample Mojolicious project running two servers from the same code base

# Description
This application runs a web server in http://localhost:3001 showing the current connected sessions

And a tcp server in localhost:3000 with a chat server.
You can use `nc localhost 3000` to connect ot the server.

# Install
```
carton
```

# Run
```
carton exec perl script/main.pl
```
