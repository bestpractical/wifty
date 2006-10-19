use inc::Module::Install;
name('Wifty');
version('0.01');
requires('Jifty');
requires('Text::Markdown');
requires('HTML::Scrubber');
requires('Text::Diff::HTML');
recommends('Text::KwikiFormatish');
WriteAll;
