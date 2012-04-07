var request = require('request');
var qs      = require('querystring');

class Issues {
  include $m.EventEmitter;

  private {
    var PER = 100;
    var gh  = "https://github.com/repos";
  }

  function initialize(user, repo) {
    this.repoURL = gh + '/'  + user + '/' + repo;
    this.issues = {};
  }

  function pull(page) {
    page = page || 1; 

    this.request('/issues', { page: page }, #(issues) {
      self.mergeIssues(issues);
    });
  }

  function request(path, params, cb) {
    var uri = this.repoURL + path;
    request({ uri: uri, qs: params }, #(err, resp, body) {
      if (!err && resp.statusCode == 200) {
        cb(JSON.parse(body));
      } else {
        console.log("Error:" + url, JSON.parse(params));
      }
    });
  }

  function mergeIssues(issues) {
    foreach (var issue in issues) {
      var n = issue.number;
      this.issues[n] = issue;
      this.grabMetaData(issue);
    }
  }

  function get(n) {
    return this.issues[n];
  }
}

class Issue {
}

