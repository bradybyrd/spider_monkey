////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
// 
// FIXME,Manish,2012-02-15,Not in TPS. Used in portfolio. To be removed.

function Gantt(element, options) {
  options = options || {};

  var width  = options.width  || 600;
  var height = options.height || 100;

  this._element = $(element).css({position: 'relative'});
  this._chart = Raphael(this._element.get(0), width, height);
  this._first = this.drawRectangle({topLeftX: 0, topLeftY: 0, width: 0, height: 0});

  this._milestoneCounts = [];
  this._rowHeight       = options.rowHeight       || 50;
  this._rowOffset       = options.rowOffset       || 10;
  this._maxHeight       = options.maxHeight       || 10000;
  this._milestoneOffset = options.milestoneOffset || 40;
  
  this._rowPadding      = options.rowPadding      || 0;

  this.setElementDimensions();
  this.drawBackground();
  this.grayTo(options.today);

  Gantt.current_chart = this;
}

$.extend(Gantt.prototype, {
  chartWidth: function() {
    return this._chart.width;
  },

  chartHeight: function() {
    return this._chart.height;
  },

  innerRowHeight: function() {
    return this.rowHeight() - this.rowPadding();
  },

  rowHeight: function() { 
    return this._rowHeight;
  },

  milestoneOffset: function() { 
    return this._milestoneOffset;
  },

  rowOffset: function() { 
    return this._rowOffset;
  },

  rowPadding: function() {
    return this._rowPadding;
  },

  maxHeight: function() { 
    return this._maxHeight;
  },

  setElementDimensions: function() { 
    this._element.css({
      width: this.chartWidth() + 'px',
      height: this.chartHeight() + 'px'
    });
  },

  drawBackground: function() {
    this.drawQuarterLabels();
    this.drawQuarterLines();
  },

  draw: function(obj, inBackground) {
    if (inBackground) obj.insertBefore(this._first);
    return obj;
  },

  drawRectangle: function(options) {
    var rect = this._chart.rect(options.topLeftX,
                                options.topLeftY,
                                options.width,
                                options.height,
                                options.corner_radius)
    rect.attr(options.attrs);
    return this.draw(rect, options.background);
  },

  drawLine: function(options) {
    var line = this._chart.path(options.attrs)
                          .moveTo(options.startX, options.startY)
                          .lineTo(options.endX, options.endY);
    return this.draw(line, options.background);
  },

  drawCircle: function(options) {
    var circle = this._chart.circle(options.centerX, options.centerY, options.radius);
    circle.attr(options.attrs);

    circle = this.draw(circle, options.background);

    if (options.annotation) {
      if (0 < options.centerX && options.centerX < this.chartWidth()) {
        var leftAdjust = options.annotation == 'P' ? 2 : 3;
        var el = $('<div></div>');
        el.addClass('annotation');
        el.css({left: options.centerX - leftAdjust, 
                top: options.centerY - 7,
                position: 'absolute',
                padding: 0,
                margin: 0});
        el.html(options.annotation);
        this.addHtmlElement(el);
        circle.annotation = el;
      }
    }
    return circle;
  },

  drawTriangle: function(options) {
    options.radius = options.radius + (options.radius / 4);
    options.centerY += 2;
    var triangle = this._chart.triangle(options.centerX, options.centerY, options.radius);
    triangle.attr(options.attrs);
    return this.draw(triangle, options.background);
  },

  crossHatch: function(options) {
    var path = this._chart.path({stroke: options.color, 'stroke-width': 3});

    var i;
    var startX;
    for (i = 0; i * 10 < options.width; ++i) {
      startX = options.startX + i * 10 + 1;
      path.moveTo(startX, options.startY + 1);
      var endx = options.startX + (i * 10) + 8;
      var endy = options.startY + options.height - 1;
      if (endx < options.width + options.startX) {
        path.lineTo(endx, endy);
      } else {
        var sx = startX,
            sy = options.startY,
            ex = endx,
            ey = endy,
            slope = (ey - sy) / (ex - sx);
        newX = options.width + options.startX - 1;
        newY = slope * (newX - sx) + sy;
        path.lineTo(newX, newY);
      }
    }
    return this.draw(path);
  },
  
  addHtmlElement: function(el) {
    return this._element.prepend(el.preserveNewlines().formatLabelText());
    //return this._element.prepend(el.escapeHtml().preserveNewlines().formatLabelText());
  },

  grayTo: function(day) {
    this.drawRectangle({
      topLeftX: 0,
      topLeftY: 0,
      width: this.days(day),
      height: this.maxHeight(),
      background: true,
      attrs: {
        fill: '#eee',
        stroke: '#eee'
      }
    });
  },

  resizeChart: function(y) {
    if (this.chartHeight() < y + this.rowOffset()) { 
      this._chart.setSize(this.chartWidth(), this.chartHeight() + this.rowHeight() + this.rowOffset());
      this.setElementDimensions();
    }
  },

  constrainLeft: function(left) {
    return this.chartWidth() < left ? this.chartWidth() : left;
  },

  repositionChart: function(left) {
    if (this._element.css('left') == 'auto' || left > parseInt(this._element.css('left'))) 
      this._element.css({left: left});
  },

  rowToY: function(row) {
    return (this.rowHeight() * row) + this.rowOffset();
  },

  bar: function(options) {
    var row        = options.row;
    var left       = this.days(options.start);
    var width      = this.days(options.end) - left;
    var color      = options.color || '#fff';
    var leftLabel  = options.leftLabel;
    var rightLabel = options.rightLabel;
    var title      = options.title;
    var hatch      = options.crossHatch;
    var bar_id     = options.id;

    this.resizeChart(this.rowToY(row + 1));

    this.drawRectangle({
      topLeftX: left,
      topLeftY: this.rowToY(row),
      width: width,
      height: this.rowHeight() - this.rowPadding(),
      attrs: { fill: color }
    });
    if (hatch) 
      this.crossHatch({startX: left, startY: this.rowToY(row), width: width, height: this.rowHeight() - this.rowPadding(), color: hatch});

    if (leftLabel)  this.barLabel(leftLabel, row, left, true);
    if (rightLabel) this.barLabel(rightLabel, row, left + 5 + width);
    if (title)      this.barTitle(title, options.row, bar_id);
    if (options.end > 365 && options.start < 365) this.barFadeTail(row);
    if (options.start < 0 && options.end > 0) this.barFadeHead(row)
  },

  barLabel: function(text, row, left, rightAlign) {
    var label = $('<div>' + text + '</div>');
    label.css({
      position: 'absolute',
      top: this.rowToY(row) + this.rowOffset() + 'px',
      left: this.constrainLeft(left) + 'px',
      fontSize: '14px',
      padding: '3px',
      zIndex: '3',
      backgroundColor: 'white',
      border: '1px solid #aaa'
    });
    this.addHtmlElement(label);
    if (rightAlign) {
      label.css({
        left: parseInt(label.css('left')) - label.width() - 10 + "px"
      });
    }
  },

  barFadeHead: function(row) {
    this._chart.image('/images/bar_fade_head.png', 0, this.rowToY(row) - 1, 35, this.innerRowHeight() + 2);
  },

  barFadeTail: function(row) {
    this._chart.image('/images/bar_fade_tail.png', this.chartWidth() - 35, this.rowToY(row) - 1, 35, this.innerRowHeight() + 2);
  },

  barTitle: function(text, row, bar_id) {
    var title = $('<div>' +  + '</div>');
    title.addClass('bar_title');
    title.addClass('bar_id_'+bar_id);
    title.css({
      position: 'absolute',
      top: this.rowToY(row) + this.rowOffset() + 'px'
    });
    this.addHtmlElement(title);
    $('.bar_id_'+bar_id)[0].innerHTML = text;
    this.repositionChart(title.width());
    title.css({left: -title.width() - 5 + "px"});
  },

  incrementMilestoneCount: function(row) {
    this._milestoneCounts[row] = this.getMilestoneCount(row) + 1;
  },

  getMilestoneCount: function(row) {
    return this._milestoneCounts[row] || 0;
  },

  tooltip: function(day, row, text, options) {
    if (options == undefined) options = {};
    var textStyles = options.textStyles
    var handleShape = options.handleShape

    var top = this.rowToY(row + 1) - (this.rowHeight() / 2) - 5;
    var bottom = top + (this.rowHeight() * 1.3) + (this.milestoneOffset() * this.getMilestoneCount(row));
    day = this.days(day);
    var stone = this.milestoneText(day, bottom - 50, text, {styles: textStyles}).hide();

    var shape;
    if (handleShape == 'triangle') {
      shape = this.drawTriangle({ centerX: day, centerY: top, radius: 7.5, attrs: {fill: '#aaa'} });
    } else {
      shape = this.drawCircle({ centerX: day, centerY: top, radius: 7.5, attrs: {fill: '#aaa'}, annotation: options.annotation });
    }

    function over() {
      stone.show();
      shape.attr('fill', 'yellow');
      $(shape.annotation).css({fontWeight: 'bolder'});
    }
    function off() {
      stone.hide();
      shape.attr('fill', '#aaa');
      $(shape.annotation).css({fontWeight: 'normal'});
    }

    $(shape.node).hover(over, off);
    if (shape.annotation) shape.annotation.hover(over, off);
  },

  milestone: function(day, row, label, shape) {
    var top = this.rowToY(row + 1) - this.rowHeight() / 2;
    var bottom = top + (this.rowHeight() * 1.3) + (this.milestoneOffset() * this.getMilestoneCount(row));
    day = this.days(day);
    this.drawLine({ startX: day, startY: top, endX: day, endY: bottom });
    this.milestoneText(day, bottom, label, {shortLength: 8});
    this.incrementMilestoneCount(row);

    if (shape == 'triangle') {
      this.drawTriangle({ centerX: day, centerY: top, radius: 5, attrs: {fill: '#aaa'} });
    } else { 
      this.drawCircle({ centerX: day, centerY: top, radius: 5, attrs: {fill: '#aaa'} });
    }
  },

  shortenText: function(text, length) {
    shortText = (text.substr(0, 8) + '...').ltrim();
    var n = shortText.indexOf("\n");
    if (n > 0)
      shortText = shortText.substr(0, n) + '...';

    return shortText;
  },

  setupTextExpand: function(element, text, shortText) {
    element.hover(function() {
      $(this).html(text).preserveNewlines().css({
        zIndex: "1000"
      });
    },
    function() {
      $(this).html(shortText).css({
        zIndex: "3"
      });
    });
  },

  milestoneText: function(x, y, text, options) {
    if (options == undefined) options = {};
    this.resizeChart(y);

    var styles = options.styles;
    var shorten = options.shortLength ? true : false;
    var shortLength = options.shortLength;

    var el = $('<div></div>');
    el.css({
      border: '1px solid #aaa',
      backgroundColor: '#eee',
      left: x - 6 + 'px', 
      top: y + 'px',
      position: 'absolute',
      fontSize: "13px",
      padding: "2px",
      zIndex: "3",
      whiteSpace: 'nowrap',
      cursor: 'default'
    });
    el.css(styles);

    if (shorten) {
      var shortText = this.shortenText(text, shortLength);
      this.setupTextExpand(el, text, shortText);
      text = shortText;
    }
    el.html(text);
    this.addHtmlElement(el);
    return el;
  },

  labelLine: function(day, label) {
    var h = this.maxHeight();
    day = this.days(day);
    this.drawLine({startX: day, startY: 0, endX: day, endy: h, background: true});

    var el = $('<div class="labelLine">'+label+'</div>');
    el.css({
      position: 'absolute',
      left: day + 'px',
      borderLeft: '2px solid #333',
      paddingLeft: '5px'
    });
    this.addHtmlElement(el);
  },

  days: function(n) {
    return this.chartWidth() / (365 / n);
  },

  drawQuarterLabels: function(qNum) {
    if (qNum == undefined) qNum = 4;
    if (qNum > 0) {
      this.addHtmlElement(this.quarterLabel(qNum));
      this.drawQuarterLabels(qNum - 1);
    }
  },

  quarterLabel: function(qNum) {
    var style = {position: 'absolute', top: '-17px', left: ((qNum - 1) * this.chartWidth() / 4) + 'px'};
    return $('<div class="quarter">Q' + qNum + '</div>').css(style);
  },

  drawQuarterLines: function(qNum) {
    if (qNum == undefined) qNum = 5;
    if (qNum > 0) {
      this.quarterLine(qNum);
      this.drawQuarterLines(qNum - 1);
    }
  },

  quarterLine: function(qNum) {
    var w = this.chartWidth();
    var h = this.maxHeight();
    var lineAttrs = {stroke: '#999'};

    var x = (qNum - 1) * w / 4;
    if (x == 0) ++x;
    if (x == w) --x;

    this.drawLine({startX: x, startY: 0, endX: x, endY: h, attrs: lineAttrs});
  }
});

$.fn.escapeHtml = function() {
  this.html(this.html().replace(/&/g, '&amp;').replace(/\</g, '&lt;').replace(/\>/g, '&gt;'));
  return this;
}

$.fn.preserveNewlines = function() {
  this.html(this.html().replace(/\n/g, "<br />"));
  return this;
}

$.fn.formatLabelText = function() {
  this.html(this.html().replace(/\*([^*]*)\*/g, '<b>$1</b>'));
  return this;
}

String.prototype.ltrim = function() {
	return this.replace(/^\s+/,"");
}

Raphael.fn.triangle = function(x, y, radius) {
  var x1, y1;
  var x2, y2;


  x1 = x; y1 = y - radius;

  y2 = Math.cos(Math.PI/3) * radius;
  x2 = Math.sin(Math.PI/3) * radius;


  var path = this.path();
  path.moveTo(x1, y1);
  path.lineTo(x+x2, y+y2);
  path.lineTo(x-x2, y+y2);
  path.andClose();

  
  return path;
}

