use inc::Module::Install;
name('Wifty');
version('0.02');
requires('Jifty');
requires('Text::Markdown');
requires('HTML::Scrubber');
requires('Text::Diff::HTML');
requires('XML::Atom::SimpleFeed');
requires('List::Compare');
requires('Regexp::Common');
requires('Scalar::Util');
recommends('Text::KwikiFormatish');

feature 'Export to MediaWiki script' =>
    -default => 0,
    requires('XML::Simple'),
    requires('HTML::WikiConverter'),
    requires('HTML::WikiConverter::MediaWiki'),
    ;

WriteAll;
