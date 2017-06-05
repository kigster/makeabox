if (typeof MakeABox === 'undefined') {
  var MakeABox    = {};
  window.MakeABox = MakeABox;
}

let delay = (ms, func) => setTimeout(func, ms);

let status = (message, period = 4000) => {
  $('#action-status')
    .clearQueue()
    .hide()
    .html(message)
    .fadeIn(500)
    .delay(period)
    .fadeOut(1000);
};
