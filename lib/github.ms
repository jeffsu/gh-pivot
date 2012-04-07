var request = require('request');
var qs      = require('querystring');
var url     = require('url');

export class Github {
  include $m.EventEmitter;
  private {
    var BASE = "https://api.github.com";
  }

  function initialize(u, p) {
    if (arguments.length == 2) {
      this.username = u;
      this.password = p;
    } else {
      this.token = u;
    }

    var auth = new Buffer(this.username + ':' + this.password).toString('base64');
    this.headers = { Authorization: 'Basic ' + auth };
  }

  function get(path, params, cb) {
    this.req(path, { qs: params }, cb);
  }

  function req(path, params, cb) {
    params.headers = this.headers;
    params.uri     = BASE + path;
    request(params, #(err, resp, data) {
      if (err || resp.statusCode != 200) {
        console.warn(err, params.uri, data);
        cb(err);
      } else {
        cb(null, JSON.parse(data));
      }
    });
  }

  function post(path, params, cb) {
    this.req(path, { method: 'POST', body: JSON.stringify(params) }, cb);
  }

  function repo(u, r) {
    return new Repo(u, r, this);
  }
}

class Repo {
  function initialize(user, repo, gh) {
    this.user = user;
    this.repo = repo;
    this.gh   = gh;
    this.base = '/repos/' + this.user + '/' + this.repo;
  }

  function cache() {
    issues = {};

    function sync() {

    }


  }

  function issues(filters, cb) {
    if (arguments.length == 1) cb = filters;

    this.gh.get(this.base + '/issues', filters, #(err, data) {
      if (err) return cb(err);
      data.forEach(#{ $1.__proto__ = Issue.prototype; $1.gh = self.gh; });
      cb(null, data);
    });
  }
}

class Issue {
  function initialize(gh) {
    this.gh = gh;
  }

  function save(params, cb) {
    if (this.number) {
      var ret = {};
      for (var k in this) if (k != 'gh') ret[k] = this[k];
      this.gh.post('/issues', ret, cb);
    } else {
      this.gh.post('/issues/' + this.number, params, cb);
    }
  }
}

