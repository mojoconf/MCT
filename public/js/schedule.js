;(function($) {
  var calendarHeader = {
    left: 'prev,next',
    center: 'title',
    right: 'agendaDay,all'
  };

  var calendarViews = {
    agendaDay: {
      type: 'agenda',
      allDaySlot: false,
      duration: { days: 1 },
      buttonText: 'Day'
    },
    all: {
      type: 'agenda',
      allDaySlot: false,
      duration: { days: 3 },
      buttonText: 'All'
    },
    defaultView: 'all'
  };

  var renderCalendar = function(json) {
    var $schedule = $('#schedule');
    var defaults = json.defaults;
    var firstEvent = json.events[0] || {};

    defaults.date = defaults.date || firstEvent.start;

    $schedule.fullCalendar({
      aspectRatio: parseInt($schedule.data('data-aspect-ratio') || 1),
      defaultDate: defaults.date || 'now',
      defaultView: 'all',
      editable: $schedule.data('data-editable') ? true : false,
      events: json.events,
      header: calendarHeader,
      maxTime: defaults.maxTime || '18:00:00',
      minTime: defaults.minTime || '08:00:00',
      scrollTime: defaults.scrollTime || firstEvent.start || '08:00:00',
      slotDuration: '00:30:00',
      snapDuration: '00:10:00',
      views: calendarViews
    });

    $schedule.find('.fc-all-button').click(function() {
      if (defaults.date) $schedule.fullCalendar('gotoDate', defaults.date);
    });

    $.scrollToContent();
  };

  $(document).ready(function() {
    var eventsUrl = location.href.replace(/[\?\#].*/, '').replace(/\.\w+$/, '') + '.json';
    $.get(eventsUrl, {}, renderCalendar);
  });
})(jQuery);
