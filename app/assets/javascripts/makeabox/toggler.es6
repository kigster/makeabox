
class Toggler {
  constructor(array_of_divs, array_of_durations = []) {
    this.divs = array_of_divs;
    this.divs_count = this.divs.length;
    this.durations = array_of_durations;
    this.effectDuration = 1500;

    const myself = this;

    this.delay(10, function() { myself.toggle(0) });
  }

  delay(ms, func) {
    return setTimeout(func, ms);
}

  toggle(currentIndex) {
    let nextIndex = this.nextIndex(currentIndex);

    let _curr = $(this.divs[currentIndex]);
    let _next = $(this.divs[nextIndex]);

    const myself = this;

    _curr.fadeOut(myself.effectDuration, function () {
      _next.fadeIn(myself.effectDuration);
    });

    let _toggleAfter = myself.effectDuration + myself.durations[nextIndex];

    this.delay(_toggleAfter, function () {
      myself.toggle(nextIndex);
    });

    return true;
  }

  nextIndex(index) {
    index++;
    return index % this.divs_count;
  }
}

window.MakeABox.Toggler = Toggler;
