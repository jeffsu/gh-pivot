class Server {
  private {
  }

  function start() {
    var oauth = require('oauth');
  }

  function createExpress() {
    var express   = require('express');
    var everyauth = require('everyauth');

    everyauth.github
      .appId(CLIENT_ID)
      .appSecret(SECRET)
      .findOrCreateUser(#(session, token, tokenExtra, data) {

      })
      .redirectPath('/');

    var app = express.createServer();
    app.use(everyauth.middleware());
    everyauth.helpExpress(app);
    app.listen(8080);
  }
}
