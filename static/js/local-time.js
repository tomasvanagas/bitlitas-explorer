/*
 * Bitlitas explorer: show times in the viewer's own time zone.
 *
 * The server renders every time in UTC as "YYYY-MM-DD HH:MM:SS",
 * and that text stays for visitors without JavaScript. Here:
 *  - each element with class "utc-time" is rewritten to the
 *    viewer's local time, same layout; the UTC original moves to
 *    its tooltip. The browser applies the right daylight-saving
 *    offset for each date on its own.
 *  - each element with class "utc-label" (the "UTC" next to a
 *    field name) shows the viewer's time zone instead.
 *
 * Loaded with `defer` from header.html, so it runs once the page
 * is parsed. Plain ES5, no dependencies.
 */
(function () {
    'use strict';

    var UTC_TIME = /^\s*(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\s*$/;

    function pad(n) {
        return (n < 10 ? '0' : '') + n;
    }

    // The server's layout, in local time: YYYY-MM-DD HH:MM:SS
    function formatLocal(d) {
        return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
             + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
    }

    // "Europe/Vilnius" where the browser knows it, else e.g. "UTC+2"
    function zoneName() {
        try {
            var zone = Intl.DateTimeFormat().resolvedOptions().timeZone;
            if (zone) {
                return zone;
            }
        } catch (e) {
            // No Intl: fall back to the current offset
        }
        var minutes = -new Date().getTimezoneOffset();
        var sign = minutes < 0 ? '-' : '+';
        minutes = Math.abs(minutes);
        return 'UTC' + sign + Math.floor(minutes / 60)
             + (minutes % 60 ? ':' + pad(minutes % 60) : '');
    }

    var times = document.querySelectorAll('.utc-time');
    for (var i = 0; i < times.length; i++) {
        var m = UTC_TIME.exec(times[i].textContent);
        if (!m) {
            continue;   // empty, or not a time: leave it as it is
        }
        var d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]));
        times[i].title = m[1] + '-' + m[2] + '-' + m[3] + ' '
                       + m[4] + ':' + m[5] + ':' + m[6] + ' UTC';
        times[i].textContent = formatLocal(d);
    }

    var labels = document.querySelectorAll('.utc-label');
    var zone = zoneName();
    for (var j = 0; j < labels.length; j++) {
        labels[j].textContent = zone;
        labels[j].title = 'Laikas rodomas jūsų laiko juostoje';
    }
})();
