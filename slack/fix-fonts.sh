#!/bin/sh
# Fixes the ligatures on Slack's font. You don't know you hate them until you apply this.

cat >> /Applications/Slack.app/Contents/Resources/app.asar.unpacked/src/static/ssb-interop.js <<'endtext'


document.addEventListener('DOMContentLoaded', function() {
    $(`<style>
       * {
         font-family: NotoSansJP,Noto,appleLogo,"Helvetica Neue",Helvetica,"Segoe UI",Tahoma,Arial,sans-serif !important;
         fone-variant-ligatures: no-common-ligatures;
         -moz-font-feature-settings: "liga" 0, "clig" 0;
         -webkit-font-feature-settings: "liga" 0, "clig" 0;
         font-feature-settings: "liga" 0, "clig" 0;
       }
       </style>`).appendTo("head");
});
endtext
