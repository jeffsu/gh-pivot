var request = require('request');
var qs      = require('querystring');
var url     = require('url');

export class Github {
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

  function repoTracker(u, r) {
    return new RepoTracker(new Repo(u, r, this));
  }
}


class RepoTracker {
  include $m.EventEmitter;

  private {
    var PER = 100;
  }

  function initialize(repo) {
    this.repo = repo;
    this.since = null;
    this.firstTime = true;

    this.issues     = {};
    this.milestones = {};

    this.start();
  }

  function start() {
    var meta = { issues: [], milestones: [], count: 2 };

    function finish() {
      if (meta.count == 0) {
        self.emit('ready');
      }
    }

    this.retrieveIssues(1, meta, finish);
    this.retrieveMilestones(meta, finish);
  }

  function retrieveIssues(page, meta, cb) {
    var filters = { page: page, per_page: PER };
    if (this.since) filters.since = this.since;

    this.repo.issues(filters, #(err, issues) {
      if (err) return self.emit('error', err);
      self.merge(issues, meta);
      if (issues.length == PER) {
        self.retrieveIssues(page + 1, meta, cb);
      } else {
        if (meta.issues.length) {
          self.emit('updated-issues', meta.updated);
          self.emit('updated', meta.updated);
        }
        cb();
      }
    });

  }

  function retrieveMilestones(meta, cb) {
    this.repo.milestones(#(err, ms) {
      foreach (var m in ms) {
        self.milestones[m.number] = m;
      }
      cb();
    });
  }

  function merge(issues, meta) {
    foreach (var i in issues) {
      var old = this.issues[i.number];
      if (!old) meta.issues.push(i);
      this.issues[i.number] = i;
    }
  }
}

class Repo {
  function initialize(user, repo, gh) {
    this.user = user;
    this.repo = repo;
    this.gh   = gh;
    this.base = '/repos/' + this.user + '/' + this.repo;
  }

  function issues(filters, cb) {
    if (arguments.length == 1) cb = filters;

    this.gh.get(this.base + '/issues', filters, #(err, data) {
      if (err) return cb(err);
      data.forEach(#{ $1.__proto__ = Issue.prototype; $1.gh = self.gh; });
      cb(null, data);
    });
  }

  function milestones(filters, cb) {
    if (arguments.length == 1) cb = filters;
    this.gh.get(this.base + '/milestones', filters, #(err, data) {
      if (err) return cb(err);
      data.forEach(#{ $1.__proto__ = Milestone.prototype; $1.gh = self.gh; });
      cb(null, data);
    });
  }
}

class Milestone {

}

class Issue {

}

