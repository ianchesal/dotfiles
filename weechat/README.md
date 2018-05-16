# weechat configuration

Not a dotfile, but a setup script for weechat.

## Installing weechat (macOS)

    brew install weechat --with-perl --with-ruby --with-python@2 --with-lua

## Slack Support

To enable Slack support you'll need the [wee-slack](https://github.com/wee-slack/wee-slack) plugin. I do:


    pushd ~/Development
    git clone git@github.com:wee-slack/wee-slack.git
    popd
    mkdir -p ~/.weechat/python/autoload
    pushd ~/.weechat/python/autoload
    ln -s ~/Development/wee-slack/wee_slack.py
    pushd ~/.weechat
    ln -s ~/Development/wee-slack/weemoji.json
    popd
    popd

Then register your Slack API keys in weechat according to the wee-slack documentation.

## Configuration

To configure weechat the way I like you can run `weechat` and then enter:

    /eval /exec -oc cat ${env:HOME}/Development/dotfiles/weechat/myweechat.conf

## Troubleshooting

If you `brew update` from time to you'll bork the weechat dynamic links to Perl, etc. If this happens run:

    brew reinstall weechat --with-perl --with-ruby --with-python@2 --with-lua

and you'll be back in business.

## Kudos

I got a lot of this from the published hard work of others out there. Notably:

* https://alexjj.com/blog/2016/9/setting-up-weechat/
* https://gist.github.com/pascalpoitras/8406501
* https://alicoding.com/hide-bar-item-in-weechat-for-a-specific-buffer/
