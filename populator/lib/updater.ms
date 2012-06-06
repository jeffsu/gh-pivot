class Updater {
  function initialize() {
    this.lastUpdated = 0;
  }

  function start() {
    this.intervalId = setInterval(#{ self.update() }, 30000);
  }

  function stop() {

  }

  function update() {

  }


}
