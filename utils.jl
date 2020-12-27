using Dates

function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

@delay function hfun_tag_landing_page()
  PAGE_TAGS = Franklin.globvar("fd_page_tags")
  TAG_COUNT = Franklin.invert_dict(PAGE_TAGS)
  markdown = ""
  for k in sort(collect(keys(TAG_COUNT))) 
    markdown *= "* [" * k * "](" * Franklin.joinpath("/tags/", k) * ") (" * string(length(TAG_COUNT[k])) * ")\n"
  end
  return fd2html(markdown, internal=true)
end

@delay function hfun_tag_side_bar()
  PAGE_TAGS = Franklin.globvar("fd_page_tags")
  TAG_COUNT = Franklin.invert_dict(PAGE_TAGS)
  println(TAG_COUNT)
  markdown = ""
  # we want (tag, postcount) tuples to be ordered lexicographically by descending post count and then by
  # ascending alphabetical order.
  for k in sort(collect(keys(TAG_COUNT)), by=x->(-length(TAG_COUNT[x]), x))[1:(min(length(keys(TAG_COUNT)), 5))]
    markdown *= "* ["*k*"](" * Franklin.joinpath("/tags/", k) * ") (" * string(length(TAG_COUNT[k])) * ")\n"
  end
  return fd2html(markdown, internal=true)
end

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

function hfun_test_no_delay()
  return "abc"
end

@delay function hfun_test_delay()
  return "123"
end

function hfun_reverse_title()
  return "<i>" * reverse(locvar(:title)) * "</i>"
end

# function hfun_all_posts()
#   list = readdir("blog")
#   filter!(f -> endswith(f, ".md"), list)
#   dates = [stat(joinpath("blog", f)).mtime for f in list]
#   perm = sortperm(dates, rev=true)
#   idxs = perm[1:min(3, length(perm))]
#   io = IOBuffer()
#   write(io, "<ul>")
#   for (k, i) in enumerate(idxs)
#       fi = "/blog/" * splitext(list[i])[1] * "/"
#       write(io, """<li><a href="$fi">Post $k</a></li>\n""")
#   end
#   write(io, "</ul>")
#   return String(take!(io))
# end