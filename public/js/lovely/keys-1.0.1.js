/**
 * lovely.io 'keys' module v1.0.1
 *
 * Copyright (C) 2011 Nikolay Nemshilov
 */
Lovely("keys-1.0.1",["dom-1.0.2"],function(a){var b={},c,d,e,f,g,h,i,j,k,l,m,n;i=this.Lovely.module("core"),j=this.Lovely.module("dom-1.0.2"),c=i.A,f=j.Event,e=j.Element,d=j.Document,h=j.Window,f.Keys={BACKSPACE:8,TAB:9,ENTER:13,ESC:27,SPACE:32,PAGEUP:33,PAGEDOWN:34,END:35,HOME:36,LEFT:37,UP:38,RIGHT:39,DOWN:40,INSERT:45,DELETE:46},n=[e,d,h],k=function(a){var b;b=a.prototype.on;return a.prototype.on=function(a){var d,e,g,h,i,j,k,l;d=c(arguments),a=d[0];if(typeof a==="string"){h=a.split(/[\+\-\_ ]+/),h=(h[h.length-1]||"").toUpperCase();if(h in f.Keys||/^[A-Z0-9]$/.test(h))i=/(^|\+|\-| )(meta|alt)(\+|\-| )/i.test(a),g=/(^|\+|\-| )(ctl|ctrl)(\+|\-| )/i.test(a),l=/(^|\+|\-| )(shift)(\+|\-| )/i.test(a),e=f.Keys[h]||h.charCodeAt(0),k=d.slice(1),j=k.shift(),typeof j==="string"&&(j=this[j]||function(){}),d=["keydown",function(a){if(a.keyCode===e&&(!i||a.metaKey||a.altKey)&&(!g||a.ctrlKey)&&(!l||a.shiftKey))return j.call(this,[a].concat(k))}]}return b.apply(this,d)}};for(l=0,m=n.length;l<m;l++)g=n[l],k(g);b.version="1.0.1";return b})