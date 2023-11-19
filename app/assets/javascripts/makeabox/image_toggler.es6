class ImageSwapper {
  constructor(div_array, image_url_array, duration_array = [], effectDelay = 1500) {
    this.divs           = div_array;
    this.divs_count     = this.divs.length;
    this.images         = image_url_array;
    this.durations      = duration_array;
    this.effectDuration = 1500;

    const myself = this;

    this.delay(10, function() { myself.toggle(0) });
  }

  delay(ms, func) {
    return setTimeout(func, ms);
  }

  toggle(currentIndex) {
    let nextIndex = this.nextIndex(currentIndex);

    let _curr = $(this.divs[ currentIndex ]);
    let _next = $(this.divs[ nextIndex ]);

    const myself = this;

    _curr.fadeOut(myself.effectDuration, function() {
      _next.fadeIn(myself.effectDuration);
    });

    let _toggleAfter = myself.effectDuration + myself.durations[ nextIndex ];

    this.delay(_toggleAfter, function() {
      myself.toggle(nextIndex);
    });

    return true;
  }

  nextIndex(index) {
    index++;
    return index % this.divs_count;
  }
}

window.Makeabox.Toggler = Toggler;
