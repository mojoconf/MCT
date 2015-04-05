;(function($) {
  $.scrollToContent = function() {
    var referrer = $('body').attr('data-referrer');
    if (referrer && location.host.indexOf(referrer) == 0 && $('body').scrollTop() < 40) {
      $('html, body').animate({
        scrollTop: $('.content-wrapper').offset().top - 40
      }, 100);
    }
  };

  $(document).ready(function() { $.scrollToContent(); });
})(jQuery);
