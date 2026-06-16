# dotfiles/bookmarklets

Browser bookmarklets — snippets of JavaScript saved as the URL of a browser
bookmark. To use one, create a new bookmark and paste the file's contents
(starting with `javascript:`) as its address; clicking the bookmark runs the
script against the current page.

`12ft.io.js` opens the current page through the `12ft.io` reader proxy by
rewriting the URL to `https://12ft.io/<hostname><path>` in a new tab.
