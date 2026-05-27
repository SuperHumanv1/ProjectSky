/*!
 * jQuery Mobile Events
 * by Ben Major
 * Licensed under the MIT License
 */

"use strict";

(function ($) {

  // ─────────────────────────────────────────────
  // CONFIG: ค่าตั้งต้นทั้งหมด
  // ─────────────────────────────────────────────
  var TOUCH = "ontouchstart" in window;

  var cfg = {
    tap_pixel_range:      5,
    swipe_h_threshold:    50,
    swipe_v_threshold:    50,
    taphold_threshold:    750,
    doubletap_int:        500,
    shake_threshold:      15,
    touch_capable:        TOUCH,
    orientation_support:  "orientation" in window && "onorientationchange" in window,

    startevent:   TOUCH ? "touchstart" : "mousedown",
    endevent:     TOUCH ? "touchend"   : "mouseup",
    moveevent:    TOUCH ? "touchmove"  : "mousemove",
    tapevent:     TOUCH ? "tap"        : "click",
    scrollevent:  TOUCH ? "touchmove"  : "scroll",

    hold_timer: null,
    tap_timer:  null,
  };

  // ─────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────
  $.touch = {};

  $.isTouchCapable    = function () { return cfg.touch_capable; };
  $.getStartEvent     = function () { return cfg.startevent; };
  $.getEndEvent       = function () { return cfg.endevent; };
  $.getMoveEvent      = function () { return cfg.moveevent; };
  $.getTapEvent       = function () { return cfg.tapevent; };
  $.getScrollEvent    = function () { return cfg.scrollevent; };

  $.touch.setSwipeThresholdX  = function (v) { assertNumber(v); cfg.swipe_h_threshold = v; };
  $.touch.setSwipeThresholdY  = function (v) { assertNumber(v); cfg.swipe_v_threshold = v; };
  $.touch.setDoubleTapInt     = function (v) { assertNumber(v); cfg.doubletap_int     = v; };
  $.touch.setTapHoldThreshold = function (v) { assertNumber(v); cfg.taphold_threshold = v; };
  $.touch.setTapRange         = function (v) { assertNumber(v); cfg.tap_pixel_range   = v; };

  function assertNumber(v) {
    if (typeof v !== "number") throw new Error("Parameter must be a number");
  }

  // ─────────────────────────────────────────────
  // HELPER: dispatch event ด้วย type ชั่วคราว
  // ─────────────────────────────────────────────
  function triggerCustom(elem, eventName, originalEvent, data) {
    var oldType = originalEvent.type;
    originalEvent.type = eventName;
    $.event.dispatch.call(elem, originalEvent, data);
    originalEvent.type = oldType;
  }

  // ─────────────────────────────────────────────
  // HELPER: ดึง position / offset จาก event
  // ─────────────────────────────────────────────
  function getPos(e, index) {
    index = index || 0;
    var orig = e.originalEvent;
    if (cfg.touch_capable && orig.touches && orig.touches[index]) {
      return { x: orig.touches[index].pageX, y: orig.touches[index].pageY };
    }
    if (cfg.touch_capable && orig.changedTouches && orig.changedTouches[index]) {
      return { x: orig.changedTouches[index].pageX, y: orig.changedTouches[index].pageY };
    }
    return { x: e.pageX, y: e.pageY };
  }

  function getOffset(e, $el, index) {
    index = index || 0;
    var pos  = getPos(e, index);
    var off  = $el.offset() || { left: 0, top: 0 };
    return {
      x: Math.round(pos.x - off.left),
      y: Math.round(pos.y - off.top),
    };
  }

  // ─────────────────────────────────────────────
  // REGISTER: ชื่อ event ทั้งหมดเป็น fn shortcuts
  // ─────────────────────────────────────────────
  $.attrFn = $.attrFn || {};

  var eventNames = [
    "tapstart", "tapend", "tapmove", "tap", "singletap", "doubletap",
    "taphold", "swipe", "swipeup", "swiperight", "swipedown", "swipeleft",
    "swipeend", "scrollstart", "scrollend", "orientationchange",
    "tap2", "taphold2",
  ];

  $.each(eventNames, function (i, name) {
    $.fn[name]    = function (fn) { return fn ? this.on(name, fn) : this.trigger(name); };
    $.attrFn[name] = true;
  });

  // ─────────────────────────────────────────────
  // EVENT: tapstart
  // ─────────────────────────────────────────────
  $.event.special.tapstart = {
    setup: function () {
      var elem = this, $el = $(elem);

      $el.on(cfg.startevent, function handler(e) {
        $el.data("callee", handler);
        if (e.which && e.which !== 1) return false;

        var pos = getPos(e);
        var data = {
          position: pos,
          offset:   getOffset(e, $el),
          time:     Date.now(),
          target:   e.target,
        };
        triggerCustom(elem, "tapstart", e, data);
        return true;
      });
    },
    remove: function () {
      $(this).off(cfg.startevent, $(this).data("callee"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: tapmove
  // ─────────────────────────────────────────────
  $.event.special.tapmove = {
    setup: function () {
      var elem = this, $el = $(elem);

      $el.on(cfg.moveevent, function handler(e) {
        $el.data("callee", handler);
        var data = {
          position: getPos(e),
          offset:   getOffset(e, $el),
          time:     Date.now(),
          target:   e.target,
        };
        triggerCustom(elem, "tapmove", e, data);
        return true;
      });
    },
    remove: function () {
      $(this).off(cfg.moveevent, $(this).data("callee"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: tapend
  // ─────────────────────────────────────────────
  $.event.special.tapend = {
    setup: function () {
      var elem = this, $el = $(elem);

      $el.on(cfg.endevent, function handler(e) {
        $el.data("callee", handler);
        var data = {
          position: getPos(e),
          offset:   getOffset(e, $el),
          time:     Date.now(),
          target:   e.target,
        };
        triggerCustom(elem, "tapend", e, data);
        return true;
      });
    },
    remove: function () {
      $(this).off(cfg.endevent, $(this).data("callee"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: taphold
  // ─────────────────────────────────────────────
  $.event.special.taphold = {
    setup: function () {
      var elem = this, $el = $(elem);
      var startTarget = null;
      var startPos    = { x: 0, y: 0 };
      var currentPos  = { x: 0, y: 0 };
      var startTime   = 0;

      $el.on(cfg.startevent, function handler(e) {
        if (e.which && e.which !== 1) return false;
        $el.data("tapheld", false);
        $el.data("callee1", handler);

        var orig = e.originalEvent;
        startTarget = e.target;
        startTime   = Date.now();
        startPos.x  = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        startPos.y  = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;
        currentPos.x = startPos.x;
        currentPos.y = startPos.y;

        var thresholdData = $el.parent().data("threshold") || $el.data("threshold");
        var threshold = (thresholdData !== undefined && thresholdData !== false && parseInt(thresholdData))
          ? parseInt(thresholdData)
          : cfg.taphold_threshold;

        cfg.hold_timer = window.setTimeout(function () {
          var dx = Math.abs(startPos.x - currentPos.x);
          var dy = Math.abs(startPos.y - currentPos.y);
          var inRange = dx <= cfg.tap_pixel_range && dy <= cfg.tap_pixel_range;

          if (e.target === startTarget && inRange) {
            $el.data("tapheld", true);

            var touches = e.originalEvent.targetTouches ? e.originalEvent.targetTouches : [e];
            var touchData = [];

            for (var i = 0; i < touches.length; i++) {
              touchData.push({
                position: getPos(e, i),
                offset:   getOffset(e, $el, i),
                time:     Date.now(),
                target:   e.target,
                duration: Date.now() - startTime,
              });
            }

            var eventName = (touches.length === 2) ? "taphold2" : "taphold";
            triggerCustom(elem, eventName, e, touchData);
          }
        }, threshold);

        return true;
      })
      .on(cfg.endevent, function handler2(e) {
        $el.data("callee2", handler2);
        $el.data("tapheld", false);
        window.clearTimeout(cfg.hold_timer);
      })
      .on(cfg.moveevent, function handler3(e) {
        $el.data("callee3", handler3);
        currentPos.x = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        currentPos.y = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;
      });
    },
    remove: function () {
      $(this)
        .off(cfg.startevent, $(this).data("callee1"))
        .off(cfg.endevent,   $(this).data("callee2"))
        .off(cfg.moveevent,  $(this).data("callee3"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: doubletap
  // ─────────────────────────────────────────────
  $.event.special.doubletap = {
    setup: function () {
      var elem = this, $el = $(elem);
      var timer       = null;
      var firstTapData = null;
      var firstOrig    = null;
      var suppressing  = false;

      $el.on(cfg.startevent, function handler(e) {
        if (e.which && e.which !== 1) return true;
        $el.data("doubletapped", false);
        $el.data("callee1", handler);
        firstOrig = e.originalEvent;

        if (!firstTapData) {
          firstTapData = {
            position: getPos(e),
            offset:   getOffset(e, $el),
            time:     Date.now(),
            target:   e.target,
            element:  e.originalEvent.srcElement,
            index:    $(e.target).index(),
          };
        }
        return true;
      })
      .on(cfg.endevent, function handler2(e) {
        $el.data("callee2", handler2);
        var now      = Date.now();
        var lastTouch = $el.data("lastTouch") || (now + 1);
        var interval  = now - lastTouch;

        window.clearTimeout(timer);

        if (interval < cfg.doubletap_int && $(e.target).index() === firstTapData.index && interval > 100) {
          $el.data("doubletapped", true);
          window.clearTimeout(cfg.tap_timer);

          var secondTapData = {
            position: getPos(e),
            offset:   getOffset(e, $el),
            time:     Date.now(),
            target:   e.target,
            element:  e.originalEvent.srcElement,
            index:    $(e.target).index(),
          };

          var detail = {
            firstTap:  firstTapData,
            secondTap: secondTapData,
            interval:  secondTapData.time - firstTapData.time,
          };

          if (!suppressing) {
            triggerCustom(elem, "doubletap", e, detail);
            firstTapData = null;
          }

          suppressing = true;
          window.setTimeout(function () { suppressing = false; }, cfg.doubletap_int);

        } else {
          $el.data("lastTouch", now);
          timer = window.setTimeout(function () {
            firstTapData = null;
            window.clearTimeout(timer);
          }, cfg.doubletap_int, [e]);
        }

        $el.data("lastTouch", now);
      });
    },
    remove: function () {
      $(this)
        .off(cfg.startevent, $(this).data("callee1"))
        .off(cfg.endevent,   $(this).data("callee2"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: singletap
  // ─────────────────────────────────────────────
  $.event.special.singletap = {
    setup: function () {
      var elem = this, $el = $(elem);
      var startTarget = null;
      var startTime   = null;
      var startPos    = { x: 0, y: 0 };

      $el.on(cfg.startevent, function handler(e) {
        if (e.which && e.which !== 1) return true;
        $el.data("callee1", handler);
        startTime   = Date.now();
        startTarget = e.target;
        startPos.x  = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        startPos.y  = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;
        return true;
      })
      .on(cfg.endevent, function handler2(e) {
        $el.data("callee2", handler2);
        if (e.target !== startTarget) return;

        var endX = e.originalEvent.changedTouches ? e.originalEvent.changedTouches[0].pageX : e.pageX;
        var endY = e.originalEvent.changedTouches ? e.originalEvent.changedTouches[0].pageY : e.pageY;

        cfg.tap_timer = window.setTimeout(function () {
          var dx = startPos.x - endX;
          var dy = startPos.y - endY;
          var inRange = (dx >= -cfg.tap_pixel_range && dx <= cfg.tap_pixel_range)
                     && (dy >= -cfg.tap_pixel_range && dy <= cfg.tap_pixel_range);

          if (!$el.data("doubletapped") && !$el.data("tapheld") && inRange) {
            var data = {
              position: getPos(e),
              offset:   getOffset(e, $el),
              time:     Date.now(),
              target:   e.target,
            };
            if (data.time - startTime < cfg.taphold_threshold) {
              triggerCustom(elem, "singletap", e, data);
            }
          }
        }, cfg.doubletap_int);
      });
    },
    remove: function () {
      $(this)
        .off(cfg.startevent, $(this).data("callee1"))
        .off(cfg.endevent,   $(this).data("callee2"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: tap
  // ─────────────────────────────────────────────
  $.event.special.tap = {
    setup: function () {
      var elem = this, $el = $(elem);
      var isTapping   = false;
      var startTarget = null;
      var startTime   = 0;
      var startPos    = { x: 0, y: 0 };
      var startTouches = null;

      $el.on(cfg.startevent, function handler(e) {
        $el.data("callee1", handler);
        if (e.which && e.which !== 1) return true;

        isTapping    = true;
        startTarget  = e.target;
        startTime    = Date.now();
        startPos.x   = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        startPos.y   = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;
        startTouches = e.originalEvent.targetTouches ? e.originalEvent.targetTouches : [e];
        return true;
      })
      .on(cfg.endevent, function handler2(e) {
        $el.data("callee2", handler2);

        var endX = e.originalEvent.targetTouches ? e.originalEvent.changedTouches[0].pageX : e.pageX;
        var endY = e.originalEvent.targetTouches ? e.originalEvent.changedTouches[0].pageY : e.pageY;
        var dx   = startPos.x - endX;
        var dy   = startPos.y - endY;
        var inRange = (dx >= -cfg.tap_pixel_range && dx <= cfg.tap_pixel_range)
                   && (dy >= -cfg.tap_pixel_range && dy <= cfg.tap_pixel_range);

        if (e.target === startTarget && isTapping && (Date.now() - startTime) < cfg.taphold_threshold && inRange) {
          var touchData = [];
          var orig = e.originalEvent;

          for (var i = 0; i < startTouches.length; i++) {
            touchData.push({
              position: getPos(e, i),
              offset:   getOffset(e, $el, i),
              time:     Date.now(),
              target:   e.target,
            });
          }

          var eventName = (startTouches.length === 2) ? "tap2" : "tap";
          triggerCustom(elem, eventName, e, touchData);
        }
      });
    },
    remove: function () {
      $(this)
        .off(cfg.startevent, $(this).data("callee1"))
        .off(cfg.endevent,   $(this).data("callee2"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: swipe
  // ─────────────────────────────────────────────
  $.event.special.swipe = {
    setup: function () {
      var elem = this;
      var $el  = $(elem);
      var startPos  = { x: 0, y: 0 };
      var currentPos = { x: 0, y: 0 };
      var startData  = null;
      var tracking   = false;
      var didSwipe   = false;

      $el.on(cfg.startevent, function handler(e) {
        $el = $(e.currentTarget);
        $el.data("callee1", handler);

        startPos.x = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        startPos.y = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;
        currentPos.x = startPos.x;
        currentPos.y = startPos.y;
        tracking  = true;
        didSwipe  = false;
        startData = {
          position: getPos(e),
          offset:   getOffset(e, $el),
          time:     Date.now(),
          target:   e.target,
        };
      })
      .on(cfg.moveevent, function handler2(e) {
        $el = $(e.currentTarget);
        $el.data("callee2", handler2);

        currentPos.x = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageX : e.pageX;
        currentPos.y = e.originalEvent.targetTouches ? e.originalEvent.targetTouches[0].pageY : e.pageY;

        var xThr = parseInt($el.parent().data("xthreshold") || $el.data("xthreshold")) || cfg.swipe_h_threshold;
        var yThr = parseInt($el.parent().data("ythreshold") || $el.data("ythreshold")) || cfg.swipe_v_threshold;
        var direction = getSwipeDirection(startPos, currentPos, xThr, yThr);

        if (direction && tracking) {
          var endData = {
            position: getPos(e),
            offset:   getOffset(e, $el),
            time:     Date.now(),
            target:   e.target,
          };
          var detail = buildSwipeDetail(startData, endData, direction);
          startPos.x = 0; startPos.y = 0;
          currentPos.x = 0; currentPos.y = 0;
          tracking = false;
          didSwipe = true;
          $el.trigger("swipe", detail).trigger("swipe" + direction, detail);
        }
      })
      .on(cfg.endevent, function handler3(e) {
        $el = $(e.currentTarget);
        $el.data("callee3", handler3);

        if (didSwipe) {
          var xThr = parseInt($el.data("xthreshold")) || cfg.swipe_h_threshold;
          var yThr = parseInt($el.data("ythreshold")) || cfg.swipe_v_threshold;
          var endData = {
            position: getPos(e),
            offset:   getOffset(e, $el),
            time:     Date.now(),
            target:   e.target,
          };
          var direction = getSwipeDirection(startData.position, endData.position, xThr, yThr);
          var detail    = buildSwipeDetail(startData, endData, direction);
          $el.trigger("swipeend", detail);
        }

        tracking = false;
        didSwipe = false;
      });
    },
    remove: function () {
      $(this)
        .off(cfg.startevent, $(this).data("callee1"))
        .off(cfg.moveevent,  $(this).data("callee2"))
        .off(cfg.endevent,   $(this).data("callee3"));
    },
  };

  // HELPER: คำนวณทิศทาง swipe
  function getSwipeDirection(start, end, xThr, yThr) {
    if (start.y > end.y && start.y - end.y > yThr) return "up";
    if (start.x < end.x && end.x - start.x > xThr) return "right";
    if (start.y < end.y && end.y - start.y > yThr) return "down";
    if (start.x > end.x && start.x - end.x > xThr) return "left";
    return null;
  }

  // HELPER: สร้าง swipe detail object
  function buildSwipeDetail(startData, endData, direction) {
    return {
      startEvnt:  startData,
      endEvnt:    endData,
      direction:  direction || "",
      xAmount:    Math.abs(startData.position.x - endData.position.x),
      yAmount:    Math.abs(startData.position.y - endData.position.y),
      duration:   endData.time - startData.time,
    };
  }

  // ─────────────────────────────────────────────
  // EVENT: scrollstart / scrollend
  // ─────────────────────────────────────────────
  $.event.special.scrollstart = {
    setup: function () {
      var elem     = this;
      var $el      = $(elem);
      var scrolling = false;
      var timer;

      function fireEvent(e, isStart) {
        scrolling = isStart;
        triggerCustom(elem, isStart ? "scrollstart" : "scrollend", e);
      }

      $el.on(cfg.scrollevent, function handler(e) {
        $el.data("callee", handler);
        if (!scrolling) fireEvent(e, true);
        clearTimeout(timer);
        timer = setTimeout(function () { fireEvent(e, false); }, 50);
      });
    },
    remove: function () {
      $(this).off(cfg.scrollevent, $(this).data("callee"));
    },
  };

  // ─────────────────────────────────────────────
  // EVENT: orientationchange
  // ─────────────────────────────────────────────
  var $win          = $(window);
  var portraitModes = { 0: true, 180: true };
  var lastOrientation;

  // ปรับ portrait map ตาม initial orientation จริง
  if (cfg.orientation_support) {
    var w = window.innerWidth  || $win.width();
    var h = window.innerHeight || $win.height();
    var isLandscape = w > h && (w - h) > 50;
    var isPortraitAngle = portraitModes[window.orientation];
    if (isLandscape && isPortraitAngle || !isLandscape && !isPortraitAngle) {
      portraitModes = { "-90": true, 90: true };
    }
  }

  function getOrientation() {
    var doc = document.documentElement;
    if (cfg.orientation_support) {
      return portraitModes[window.orientation] ? "portrait" : "landscape";
    }
    return (doc && doc.clientWidth / doc.clientHeight < 1.1) ? "portrait" : "landscape";
  }

  function checkOrientation() {
    var current = getOrientation();
    if (current !== lastOrientation) {
      lastOrientation = current;
      $win.trigger("orientationchange");
    }
  }

  $.event.special.orientationchange = {
    setup: function () {
      if (!cfg.orientation_support) {
        lastOrientation = getOrientation();
        $win.on("throttledresize", checkOrientation);
        return true;
      }
    },
    teardown: function () {
      if (!cfg.orientation_support) {
        $win.off("throttledresize", checkOrientation);
        return true;
      }
    },
    add: function (handleObj) {
      var origHandler = handleObj.handler;
      handleObj.handler = function (e) {
        e.orientation = getOrientation();
        return origHandler.apply(this, arguments);
      };
    },
  };

  $.event.special.orientationchange.orientation = getOrientation;

  // ─────────────────────────────────────────────
  // EVENT: throttledresize
  // ─────────────────────────────────────────────
  var throttleTimer;
  var throttleLast = 0;

  function throttledResizeHandler() {
    var now  = Date.now();
    var diff = now - throttleLast;

    if (diff >= 250) {
      throttleLast = now;
      $(this).trigger("throttledresize");
    } else {
      if (throttleTimer) window.clearTimeout(throttleTimer);
      throttleTimer = window.setTimeout(checkOrientation, 250 - diff);
    }
  }

  $.event.special.throttledresize = {
    setup:    function () { $(this).on("resize",  throttledResizeHandler); },
    teardown: function () { $(this).off("resize", throttledResizeHandler); },
  };

  // ─────────────────────────────────────────────
  // ALIAS EVENTS (ชี้ไปหา parent event)
  // ─────────────────────────────────────────────
  $.each({
    scrollend:   "scrollstart",
    swipeup:     "swipe",
    swiperight:  "swipe",
    swipedown:   "swipe",
    swipeleft:   "swipe",
    swipeend:    "swipe",
    tap2:        "tap",
    taphold2:    "taphold",
  }, function (alias, parent) {
    $.event.special[alias] = {
      setup: function () { $(this).on(parent, $.noop); },
    };
  });

}(jQuery));
