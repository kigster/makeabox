Makeabox.GA = function(label) {
  if (typeof(ga) !== 'undefined' && ga !== null) {
    return ga('send', {
                hitType      : 'event',
                eventCategory: 'PDF',
                eventAction  : 'download',
                eventLabel   : label
              }
    );
  }
};
