class ImageSwapper {
  constructor(div_array, image_url_array, effectDelay = 500) {
    this.divs              = div_array
    this.images            = image_url_array
    this.effectiveDelay    = effectDelay
    this.interaction_count = 0

    const myself = this;
    this.delay(10, function() { myself.toggle(0) });
  }

  delay = (ms, func) => setTimeout(func, ms);

  toggle = currentIndex => {
    const nextIndex = this.nextIndex(currentIndex);

    const _curr = $(this.divs[ currentIndex ]);
    const _next = $(this.divs[ nextIndex ]);

    const myself = this;

    _curr.fadeOut(myself.effectDuration, function() {
      _next.fadeIn(myself.effectDuration);
    });

    let _toggleAfter = myself.effectDuration + myself.durations[ nextIndex ];

    this.delay(_toggleAfter, function() {
      myself.toggle(nextIndex);
    });

    return true;
  };

  nextIndex(index) {
    index++;
    return index % this.divs_count;
  }
}

window.Makeabox.Toggler = Toggler;
