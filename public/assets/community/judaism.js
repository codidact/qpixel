/*
The MIT License (MIT)
Copyright (c) 2013  HodofHod (https://github.com/HodofHod, http://judaism.stackexchange.com/users/883/hodofhod)
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Thanks: @Manishearth for the inject() function, and James Montagne for the draggability.
// Thanks to all who've helped debug and discuss, especially the Mac users, nebech.

(function HBKeyboard() {
  var docCookies = { //from developer.mozilla.org/en-US/docs/Web/API/document.cookie
    getItem: function (sKey) {
      return unescape(document.cookie.replace(new RegExp("(?:(?:^|.*;)\\s*" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=\\s*([^;]*).*$)|^.*$"), "$1")) || null;
    },
    setItem: function (sKey, sValue) {
      if (!sKey || /^(?:expires|max\-age|path|domain|secure)$/i.test(sKey)) {
        return false;
      }
      document.cookie = escape(sKey) + "=" + escape(sValue) + "; expires=Fri, 31 Dec 9999 23:59:59 GMT; domain=stackexchange.com; path=/";
      return true;
    },
    hasItem: function (sKey) {
      return (new RegExp("(?:^|;\\s*)" + escape(sKey).replace(/[\-\.\+\*]/g, "\\$&") + "\\s*\\=")).test(document.cookie);
    },
  };

  var currentTextfield = $('textarea, input[type=text]');
  $(document).ready(function(){
    $(document).on('focus', 'textarea, input[type=text]', function(){
      currentTextfield = $(this);
    });

    var wh = $(window).height(),
      ww = $(window).width(),
      kb = createKeyboard().hide();
    $('#hbk-toggle span').css({
      'padding': '3px',
      'text-align': 'center',
      'background-image': "none",
      'font-weight':'bolder'
    });
    $(window).resize(function(){
      kb.css({
        top: '+=' + ($(window).height() - wh) + 'px',
        left: '+=' + ($(window).width() - ww) + 'px',
      });
      if (kb.css('top') < '0px') kb.css('top','0px');
      wh = $(window).height();
      ww = $(window).width();
    });

    QPixel.addEditorButton(`א`, 'Hebrew Keyboard', () => {
      kb.toggle();
    });
  });

  function createKeyboard() {
    var stand = "קראטוןםפשדגכעיחלךףזסבהנמצתץ",
      alpha = "חזוהדגבאסןנםמלךכיטתשרקץצףפע",
      nek = ["שׁ", "שׂ", "וְ", "וֱ", "וֲ", "וֳ", "וִ", "וֵ", "וֶ", "וַ", "וָ", "וֹ", "וֻ", "וּ"],
      x = 50,
      y = 50,
      kb = $('<div class="hbkeyboard"></div>').appendTo($("body"));

    $.each(alpha.split('').concat(nek), function (i, letter) {
      kb.append('<button type="button" class="hbkey" data-t="' + letter.slice(-1) + '">' + letter + '</button>');
    });

    kb.children('button:lt(8)').wrapAll('<div class="first kbrow">');
    kb.children('button:lt(10)').wrapAll('<div class="second kbrow">');
    kb.children('button:lt(9)').wrapAll('<div class="third kbrow">');
    kb.children('button:lt(14)').wrapAll('<div class="fourth kbrow">');
    //kb.children('.first.kbrow').prepend('<button type="button" class="hbkey" data-t="&rlm;">&amp;rlm;</button>');
    kb.prepend('<div style="position:relative; height:20px;margin-bottom: 10px;"><button type="button" id="setbutton" data-t="">Settings</button><button type="button" id="closebutton" data-t="">x</button></div>');
    kb.prepend('<span style="position:absolute; top:0; right:0; color:transparent">בס"ד</span>');
    kb.append('<div class="inserts"></div>');
    kb.children('.inserts').append('<button type="button" class="hbins" data-t="&rlm;">Ins RLM</button>');
    kb.children('.inserts').append('<button type="button" class="hbins" data-t="&lrm;">Ins LRM</button>');
    $('<div class="kbsettings" style="text-align:left;"><div><input type="checkbox" id="keylayout">Use standard layout</div><div><input type="checkbox" id="rlm">Insert &amp;rlm; as text (posts only)</div></div>').appendTo(kb).hide();

    /* CSS For Keyboard and buttons */
    $('html > head').append($('<style>.hbkey:active{border: 1px solid lightgray !important;}</style>'));
    $('.kbsettings input').css('margin','5px');
    kb.css({
      position: 'fixed',
      border: '1px solid #BBB',
      padding: '1em',
      'padding-left': '1.5em',
      left: x,
      top: y,
      direction: 'ltr',
      'border-radius': '0.2em',
      'z-index': '99999',
      'background-color': 'rgb(241, 241, 241)'
    });
    $('.kbrow').css({
      position: 'relative',
      'white-space': 'nowrap',
      'text-align': 'right'
    });
    $('.zeroth, .first, .third').css({
      right: '20px'
    });
    $('.second').css('right', '10px');
    $('.fourth').css({ //nekudos row
      'text-align': 'center'
    });
    $('.hbkey').css({
      margin: '1px',
      display: 'inline-block',
      width: '32px',
      border: 'none',
      height: '31px',
      padding: 0,
      color: "#000",
      'text-shadow': "none",
      'font-family': 'FrankRuehl, New Peninim MT, Arial, sans-serif',
      'font-size': '20px',
      'vertical-align': 'top',
      'box-shadow': '1px 1px 2px 1px gray',
      'background':'inherit',//Mac Chrome
      'background-color':'inherit',//Mac Chrome
    });
    $('.fourth.kbrow .hbkey').css({
      direction:'rtl',
      padding: '0',
      width: '20px',
      'font-size': '25px',
      'min-height': '33px'
    });
    $('.hbins').css({
      'margin-top': '0.5em',
      'margin-right': '0.5em'
    });


    /* Event handling for buttons and checkboxes*/
    kb.find('.hbkey').click(function () {
      t = currentTextfield[0];
      var start = t.selectionStart,
        end = t.selectionEnd,
        text = t.value,
        chr = $(this).data('t');

      if (chr === '‏' && $('#rlm').is(':checked') && t.id !== 'input') chr = '&rlm;';//special case for rlm.
      var res = text.slice(0, start) + chr + text.slice(end),
        len = chr.length;
      $(t).val(res).trigger('input').focus();
      t.setSelectionRange(start + len, start + len);
    });

    kb.find('.hbins').click(function () {
      t = currentTextfield[0];
      var start = t.selectionStart,
        end = t.selectionEnd,
        text = t.value,
        chr = $(this).data('t');
      var res = text.slice(0, start) + chr + text.slice(end),
        len = chr.length;
      $(t).val(res).trigger('input').focus();
      t.setSelectionRange(start + len, start + len);
    });

    $('#setbutton, #closebutton')
    .css({
      border: 'none',
      background: 'transparent',
      position: 'absolute',
      top: 0,
      color: "#000",
      'text-shadow': 'none',
      'font-size': '14px',
      'font-family': 'FrankRuehl, New Peninim MT, Arial, sans-serif',
    }).off();

    $('#setbutton') //Settings button
    .css('left',0)
    .click(function () {
      $(this).text($(this).text() === "Settings" ? "Keyboard" : "Settings");
      $('.first, .second, .third, .fourth').slideToggle();
      $('.kbsettings').slideToggle();
    });

    $('#closebutton')//x button
    .css('right',0)
    .click(function () {
      kb.fadeToggle('medium');
    });

    $('#keylayout').change(function(){
      var layout = $(this).prop('checked') ? stand : alpha;
      $('.hbkey').slice(0, 27).each(function (index) {
        $(this).data('t', layout[index]).text(layout[index]);
      });
      docCookies.setItem('layoutSetting', $('#keylayout').prop('checked'));
    });

    /*$('#rlm').change(function(){
      docCookies.setItem('rlmSetting', $('#rlm').prop('checked'));
    });

    $('#rlm').prop('checked', docCookies.getItem('rlmSetting') === "true" ?  true : false).change();*/
    $('#keylayout').prop('checked', docCookies.getItem('layoutSetting') === "true" ? true : false).change();
    return kb;
  }



  //Draggability
  var drag = {
      elem: null,
      x: 0,
      y: 0,
      state: false
    },
    delta = {
      x: 0,
      y: 0
    };
  $(document).on('mousedown', '.hbkeyboard', function (e) {
    if (!drag.state) {
      drag.elem = this;
      drag.x = e.pageX;
      drag.y = e.pageY;
      drag.state = true;
    }
    return false;
  });
  $(document).mousemove(function (e) {
    if (drag.state) {
      delta.x = e.pageX - drag.x;
      delta.y = e.pageY - drag.y;
      var cur_offset = $(drag.elem).offset();

      $(drag.elem).offset({
        left: (cur_offset.left + delta.x),
        top: (cur_offset.top + delta.y)
      });
      if ($(drag.elem).css('top') < '0px') $(drag.elem).css('top','0px');
      drag.x = e.pageX;
      drag.y = e.pageY;
    }
  });
  $(document).mouseup(function () {
    drag.state && (drag.state = false);
  });
})();


// ============================================================================================== //


$(() => {
  const el = document.createElement('script');
  el.src = 'https://www.sefaria.org/linker.js';
  el.addEventListener('load', () => {
    sefaria.link();

    $(document).on('ajax:success', '.post--comments', () => {
      sefaria.link();
    });

    let linkTimeout = null;

    $('.post-field').on('focus keyup markdown', () => {
      if (linkTimeout) {
        clearTimeout(linkTimeout);
      }

      linkTimeout = setTimeout(() => {
        sefaria.link();
      }, 1000);
    });
  });
  document.body.appendChild(el);
});


// ============================================================================================== //


$(() => {
  const getSuggestions = async term => {
    const resp = await fetch(`https://sefaria.org/api/name/${term}`);
    const data = await resp.json();
    return data.completions;
  };

  const doReplacement = ev => {
    ev.preventDefault();

    const $field = $('.js-post-field');
    const $tgt = $(ev.target);
    const text = $tgt.attr('data-text');
    QPixel.replaceSelection($field, text);
    $field.trigger('markdown');
  };

  const createPopup = suggestions => {
    const $itemTemplate = $(`<a class="item" href="#"></a>`);
    return suggestions.map(s => {
      return $itemTemplate.clone().text(s).attr('data-text', s);
    });
  };

  QPixel.addEditorButton(`<i class="fas fa-torah"></i>`, 'Suggest Reference', async () => {
    const $field = $('.js-post-field');
    const selection = $field.val().substring($field[0].selectionStart, $field[0].selectionEnd) || '';
    if (!selection) {
      QPixel.createNotification('danger', 'Select some text, then click the Suggest Reference button.');
      return;
    }

    const suggestions = await getSuggestions(selection);
    const items = createPopup(suggestions);
    QPixel.createTextareaPopup(items, $field[0], doReplacement);
  });
});

// ============================================================================================== //
/** 
 * Calendar script, added 2021-04-01 by @luap42
 */

  // Use *local* time for ISO string (Date.toISOString() uses UTC).
  // We only need the date here, so punting on time.
  function toIsoDate(date) {
  var pad = function(num) {
          var norm = Math.floor(Math.abs(num));
          return (norm < 10 ? '0' : '') + norm;
      };

  return date.getFullYear() +
      '-' + pad(date.getMonth() + 1) +
      '-' + pad(date.getDate());
}


window.addEventListener("load", async () => {
  const container = document.createElement('div');
  container.innerHTML = "<div class='widget--body'><div class='_cal_label'>Today is:</div><div class='_cal_val'>loading date...</div></div>";
  container.classList.add('widget', 'has-margin-4');

  const disclaimerNotice = document.querySelector('.widget.is-yellow:first-child');
  disclaimerNotice.parentNode.insertBefore(container, disclaimerNotice.nextSibling);

  let todayDate = new Date();

  // Start new day at 8pm local time previous day (if it's 8 or later today is tomorrow).
  // Hour is zero-indexed, hence > 19 (not > 20).
  if (todayDate.getHours() > 19) {
    todayDate.setDate(todayDate.getDate() + 1);
  }

  // Use actual year and month (rather than now) in URL to dodge caching.
  const result = await fetch('https://www.hebcal.com/hebcal?v=1&cfg=json&year=' + todayDate.getFullYear() + '&month=' + (todayDate.getMonth()+1) + '&d=on&o=on');
  const response = await result.json()

  const parsedData = response.items.reduce((rv, x) => {
    (rv[x.date] = rv[x.date] || []).push(x);
    return rv;
  }, {});

  // Do not use Date.toISOString(), which uses UTC not local time.
  let now = toIsoDate(todayDate);

  const fields = parsedData[now];
  container.querySelector('._cal_val').innerHTML = "";

  fields.forEach(field => {
    const fieldContainer = document.createElement('div');
    fieldContainer.classList.add('has-font-size-larger', 'h-fw-bold', 'h-m-t-2');
    container.querySelector('._cal_val').appendChild(fieldContainer);

    fieldContainer.innerText = field.title;
  });

  const DAY_LIST = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  const todayDay = DAY_LIST[(todayDate.getDay() + 6) % 7];
  const yesterdayDay = DAY_LIST[(todayDate.getDay() + 5) % 7];


  const fieldContainer = document.createElement('div');
  fieldContainer.classList.add('h-m-t-2', 'has-font-size-caption');
  container.querySelector('._cal_val').appendChild(fieldContainer);

  fieldContainer.innerText = yesterdayDay + ' night (' + todayDay + ')';
});


