chrome.app.runtime.onLaunched.addListener(function() {
  chrome.app.window.create('index.html', {
    minWidth: 1000,
    minHeight: 800
  });
});

