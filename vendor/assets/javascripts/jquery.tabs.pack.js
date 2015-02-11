/**
 * Tabs - jQuery plugin for accessible, unobtrusive tabs
 * @requires jQuery v1.1.1
 *
 * http://stilbuero.de/tabs/
 *
 * Copyright (c) 2006 Klaus Hartl (stilbuero.de)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 * Version: 2.7.4
 * 
 * |BMC TPS Info    |jquery.tabs.js |TPSDR0034833   |DR4ST.2.7.04     |http://stilbuero.de/tabs/    |Registered |
 */
(function ($) {
    $.extend({
        tabify: {
            remoteCount: 0
        }
    });
    $.fn.tabify = function (x, w) {
        if (typeof x == 'object') w = x;
        w = $.extend({
            initial: (x && typeof x == 'number' && x > 0) ? --x : 0,
            disabled: null,
            bookmarkable: $.ajaxHistory ? true : false,
            remote: false,
            spinner: 'Loading&#8230;',
            hashPrefix: 'remote-tab-',
            fxFade: null,
            fxSlide: null,
            fxShow: null,
            fxHide: null,
            fxSpeed: 'normal',
            fxShowSpeed: null,
            fxHideSpeed: null,
            fxAutoHeight: false,
            onClick: null,
            onHide: null,
            onShow: null,
            navClass: 'tabs-nav',
            selectedClass: 'tabs-selected',
            disabledClass: 'tabs-disabled',
            containerClass: 'tabs-container',
            hideClass: 'tabs-hide',
            loadingClass: 'tabs-loading',
            tabStruct: 'div'
        },
        w || {});
        $.browser.msie6 = $.browser.msie && ($.browser.version && $.browser.version < 7 || /MSIE 6.0/.test(navigator.userAgent));

        function unFocus() {
            scrollTo(0, 0)
        }
        return this.each(function () {
            var p = this;
            var r = $('ul.' + w.navClass, p);
            r = r.size() && r || $('>ul:eq(0)', p);
            var j = $('a', r);
            if (w.remote) {
                j.each(function () {
                    var c = w.hashPrefix + (++$.tabs.remoteCount),
                        hash = '#' + c,
                        url = this.href;
                    this.href = hash;
                    $('<div id="' + c + '" class="' + w.containerClass + '"></div>').appendTo(p);
                    $(this).bind('loadRemoteTab', function (e, a) {
                        var b = $(this).addClass(w.loadingClass),
                            span = $('span', this)[0],
                            tabTitle = span.innerHTML;
                        if (w.spinner) {
                            span.innerHTML = '<em>' + w.spinner + '</em>'
                        }
                        setTimeout(function () {
                            $(hash).load(url, function () {
                                if (w.spinner) {
                                    span.innerHTML = tabTitle
                                }
                                b.removeClass(w.loadingClass);
                                a && a()
                            })
                        },
                        0)
                    })
                })
            }
            var n = $('div.' + w.containerClass, p);
            n = n.size() && n || $('>' + w.tabStruct, p);
            r.is('.' + w.navClass) || r.addClass(w.navClass);
            n.each(function () {
                var a = $(this);
                a.is('.' + w.containerClass) || a.addClass(w.containerClass)
            });
            var s = $('li', r).index($('li.' + w.selectedClass, r)[0]);
            if (s >= 0) {
                w.initial = s
            }
            if (location.hash) {
                j.each(function (i) {
                    if (this.hash == location.hash) {
                        w.initial = i;
                        if (($.browser.msie || $.browser.opera) && !w.remote) {
                            var a = $(location.hash);
                            var b = a.attr('id');
                            a.attr('id', '');
                            setTimeout(function () {
                                a.attr('id', b)
                            },
                            500)
                        }
                        unFocus();
                        return false
                    }
                })
            }
            if ($.browser.msie) {
                unFocus()
            }
            n.filter(':eq(' + w.initial + ')').show().end().not(':eq(' + w.initial + ')').addClass(w.hideClass);
            $('li', r).removeClass(w.selectedClass).eq(w.initial).addClass(w.selectedClass);
            j.eq(w.initial).trigger('loadRemoteTab').end();
            if (w.fxAutoHeight) {
                var l = function (d) {
                    var c = $.map(n.get(), function (a) {
                        var h, jq = $(a);
                        if (d) {
                            if ($.browser.msie6) {
                                a.style.removeExpression('behaviour');
                                a.style.height = '';
                                a.minHeight = null
                            }
                            h = jq.css({
                                'min-height': ''
                            }).height()
                        } else {
                            h = jq.height()
                        }
                        return h
                    }).sort(function (a, b) {
                        return b - a
                    });
                    if ($.browser.msie6) {
                        n.each(function () {
                            this.minHeight = c[0] + 'px';
                            this.style.setExpression('behaviour', 'this.style.height = this.minHeight ? this.minHeight : "1px"')
                        })
                    } else {
                        n.css({
                            'min-height': c[0] + 'px'
                        })
                    }
                };
                l();
                var q = p.offsetWidth;
                var m = p.offsetHeight;
                var v = $('#tabs-watch-font-size').get(0) || $('<span id="tabs-watch-font-size">M</span>').css({
                    display: 'block',
                    position: 'absolute',
                    visibility: 'hidden'
                }).appendTo(document.body).get(0);
                var o = v.offsetHeight;
                setInterval(function () {
                    var b = p.offsetWidth;
                    var a = p.offsetHeight;
                    var c = v.offsetHeight;
                    if (a > m || b != q || c != o) {
                        l((b > q || c < o));
                        q = b;
                        m = a;
                        o = c
                    }
                },
                50)
            }
            var u = {},
                hideAnim = {},
                showSpeed = w.fxShowSpeed || w.fxSpeed,
                hideSpeed = w.fxHideSpeed || w.fxSpeed;
            if (w.fxSlide || w.fxFade) {
                if (w.fxSlide) {
                    u['height'] = 'show';
                    hideAnim['height'] = 'hide'
                }
                if (w.fxFade) {
                    u['opacity'] = 'show';
                    hideAnim['opacity'] = 'hide'
                }
            } else {
                if (w.fxShow) {
                    u = w.fxShow
                } else {
                    u['min-width'] = 0;
                    showSpeed = 1
                }
                if (w.fxHide) {
                    hideAnim = w.fxHide
                } else {
                    hideAnim['min-width'] = 0;
                    hideSpeed = 1
                }
            }
            var t = w.onClick,
                onHide = w.onHide,
                onShow = w.onShow;
            j.bind('triggerTab', function () {
                var c = $(this).parents('li:eq(0)');
                if (p.locked || c.is('.' + w.selectedClass) || c.is('.' + w.disabledClass)) {
                    return false
                }
                var a = this.hash;
                if ($.browser.msie) {
                    $(this).trigger('click');
                    if (w.bookmarkable) {
                        $.ajaxHistory.update(a);
                        location.hash = a.replace('#', '')
                    }
                } else if ($.browser.safari) {
                    var b = $('<form action="' + a + '"><div><input type="submit" value="h" /></div></form>').get(0);
                    b.submit();
                    $(this).trigger('click');
                    if (w.bookmarkable) {
                        $.ajaxHistory.update(a)
                    }
                } else {
                    if (w.bookmarkable) {
                        location.hash = a.replace('#', '')
                    } else {
                        $(this).trigger('click')
                    }
                }
            });
            j.bind('disableTab', function () {
                var a = $(this).parents('li:eq(0)');
                if ($.browser.safari) {
                    a.animate({
                        opacity: 0
                    },
                    1, function () {
                        a.css({
                            opacity: ''
                        })
                    })
                }
                a.addClass(w.disabledClass)
            });
            if (w.disabled && w.disabled.length) {
                for (var i = 0, k = w.disabled.length; i < k; i++) {
                    j.eq(--w.disabled[i]).trigger('disableTab').end()
                }
            };
            j.bind('enableTab', function () {
                var a = $(this).parents('li:eq(0)');
                a.removeClass(w.disabledClass);
                if ($.browser.safari) {
                    a.animate({
                        opacity: 1
                    },
                    1, function () {
                        a.css({
                            opacity: ''
                        })
                    })
                }
            });
            j.bind('click', function (e) {
                var g = e.clientX;
                var d = this,
                    li = $(this).parents('li:eq(0)'),
                    toShow = $(this.hash),
                    toHide = n.filter(':visible');
                if (p['locked'] || li.is('.' + w.selectedClass) || li.is('.' + w.disabledClass) || typeof t == 'function' && t(this, toShow[0], toHide[0]) === false) {
                    this.blur();
                    return false
                }
                p['locked'] = true;
                if (toShow.size()) {
                    if ($.browser.msie && w.bookmarkable) {
                        var c = this.hash.replace('#', '');
                        toShow.attr('id', '');
                        setTimeout(function () {
                            toShow.attr('id', c)
                        },
                        0)
                    }
                    var f = {
                        display: '',
                        overflow: '',
                        height: ''
                    };
                    if (!$.browser.msie) {
                        f['opacity'] = ''
                    }
                    function switchTab() {
                        if (w.bookmarkable && g) {
                            $.ajaxHistory.update(d.hash)
                        }
                        toHide.animate(hideAnim, hideSpeed, function () {
                            $(d).parents('li:eq(0)').addClass(w.selectedClass).siblings().removeClass(w.selectedClass);
                            toHide.addClass(w.hideClass).css(f);
                            if (typeof onHide == 'function') {
                                onHide(d, toShow[0], toHide[0])
                            }
                            if (! (w.fxSlide || w.fxFade || w.fxShow)) {
                                toShow.css('display', 'block')
                            }
                            toShow.animate(u, showSpeed, function () {
                                toShow.removeClass(w.hideClass).css(f);
                                if ($.browser.msie) {
                                    toHide[0].style.filter = '';
                                    toShow[0].style.filter = ''
                                }
                                if (typeof onShow == 'function') {
                                    onShow(d, toShow[0], toHide[0])
                                }
                                p['locked'] = null
                            })
                        })
                    }
                    if (!w.remote) {
                        switchTab()
                    } else {
                        $(d).trigger('loadRemoteTab', [switchTab])
                    }
                } else {
                    alert('There is no such container.')
                }
                var a = window.pageXOffset || document.documentElement && document.documentElement.scrollLeft || document.body.scrollLeft || 0;
                var b = window.pageYOffset || document.documentElement && document.documentElement.scrollTop || document.body.scrollTop || 0;
                setTimeout(function () {
                    window.scrollTo(a, b)
                },
                0);
                this.blur();
                return w.bookmarkable && !!g
            });
            if (w.bookmarkable) {
                $.ajaxHistory.initialize(function () {
                    j.eq(w.initial).trigger('click').end()
                })
            }
        })
    };
    var y = ['triggerTab', 'disableTab', 'enableTab'];
    for (var i = 0; i < y.length; i++) {
        $.fn[y[i]] = (function (d) {
            return function (c) {
                return this.each(function () {
                    var b = $('ul.tabs-nav', this);
                    b = b.size() && b || $('>ul:eq(0)', this);
                    var a;
                    if (!c || typeof c == 'number') {
                        a = $('li a', b).eq((c && c > 0 && c - 1 || 0))
                    } else if (typeof c == 'string') {
                        a = $('li a[@href$="#' + c + '"]', b)
                    }
                    a.trigger(d)
                })
            }
        })(y[i])
    }
    $.fn.activeTab = function () {
        var c = [];
        this.each(function () {
            var a = $('ul.tabs-nav', this);
            a = a.size() && a || $('>ul:eq(0)', this);
            var b = $('li', a);
            c.push(b.index(b.filter('.tabs-selected')[0]) + 1)
        });
        return c[0]
    }
})(jQuery);