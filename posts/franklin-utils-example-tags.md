@def title = "Franklin.jl Utils Examples: Tags Ordered by Post Quantity"
@def date = "09/27/2020"
@def tags = ["julia"]
 
# Franklin.jl Utils Examples: Tags Ordered by Post Quantity
 
Franklin.jl provides a way for the user to execute arbitrary Julia functions on the markdown/html/LaTeX used in a page. For example, on my [posts](/posts)  page, all of the posts I have written are listed in order of publication date. This was done with a simple function:

```julia
function hfun_recent_posts(m::Vector{String})
  @assert length(m) == 1 "only one argument allowed for recent posts (the number of recent posts to pull)"
  n = parse(Int64, m[1])
  list = readdir("posts")
  filter!(f -> endswith(f, ".md") && f != "index.md" , list)
  markdown = ""
  posts = []
  df = DateFormat("mm/dd/yyyy")
  for (k, post) in enumerate(list)
      fi = "posts/" * splitext(post)[1]
      title = pagevar(fi, :title)
      datestr = pagevar(fi, :date)
      @assert length(datestr) == 10  "dates must be in mm/dd/yyyy format"
      date = Date(pagevar(fi, :date), df)
      push!(posts, (title=title, link=fi, date=date))
  end

  # pull all posts if n <= 0
  n = n >= 0 ? n : length(posts)+1
  for ele in sort(posts, by=x->x.date, rev=true)[1:min(length(posts), n)]
    markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link))\n"
  end

  return fd2html(markdown, internal=true)
end

function hfun_all_posts()
  return hfun_recent_posts(["-1"])
end
```

which is called in the `posts.md` file (below is the *complete* file):

```markdown
# all posts

{{ all_posts }}
```

This code can be executed as soon as the page generation starts, as it only relies on knowing local information from each page that can be retrieved and discarded when a page is looked at. When I was considering switching to Franklin, I ran into a problem where the code in `utils.jl` was being run before enough information was available for it to succeed. In particular, I wished to generate a list of tags ordered by the number of posts with that tag. This list would appear in the sidebar for each page, meaning it was generated at the same time that the page was processed (and `utils.jl` code was run), but the tag information was also collected at this time. This led to a situation where incomplete tag information was being presented on pages.

I discussed this on the Franklin slack and submitted an [issue](https://github.com/tlienart/Franklin.jl/issues/582). It was resolved after a short time by introducing a `@delay` macro, that delays the function execution until after a full pass of the website has been done (at which time, all of the relevant global values--like tag information--would be known).

[Franklin.jl's GitHub](https://github.com/tlienart/Franklin.jl) and [website](https://franklinjl.org/) provide snippets for 