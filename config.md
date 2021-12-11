<!--
Add here global page variables to use throughout your
website.
The website_* must be defined for the RSS to work
-->
@def website_title = "theoretically good with computers"
@def website_descr = "i wish i was actually good with computers"
@def website_url   = "https://mcognetta.github.io/"

@def author = "Marco Cognetta"

@def mintoclevel = 2

@def tag_page_path = "tags"

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "theoretically good with computers"
website_descr = "marco's posts about computers"
website_url   = "https://theoreticallygoodwithcomputers.com"
rss_full_content = true

<!--
Add here files or directories that should be ignored by Franklin, otherwise
these files might be copied and, if markdown, processed by Franklin which
you might not want. Indicate directories by ending the name with a `/`.
-->
@def ignore = ["node_modules/", "franklin", "franklin.pub"]

<!--
Add here global latex commands to use throughout your
pages. It can be math commands but does not need to be.
For instance:
* \newcommand{\phrase}{This is a long phrase to copy.}
-->
\newcommand{\R}{\mathbb R}
\newcommand{\scal}[1]{\langle #1 \rangle}
