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


function hfun_tag_landing_page()
  PAGE_TAGS = Franklin.globvar("fd_page_tags")
  Franklin.clean_tags()
  TAG_COUNT = Franklin.invert_dict(PAGE_TAGS)
  markdown = ""
  for k in sort(collect(keys(TAG_COUNT))) 
    markdown *= "* ["*k*"](" * Franklin.joinpath("/tag/", k) * ") (" * string(length(TAG_COUNT[k])) * ")\n"
  end
  return fd2html(markdown, internal=true)
end

function hfun_tag_side_bar()
  PAGE_TAGS = Franklin.globvar("fd_page_tags")
  print(PAGE_TAGS)
  print( "\n ========== \n")
  TAG_COUNT = Franklin.invert_dict(PAGE_TAGS)
  markdown = ""
  # we want (tag, postcount) tuples to be ordered lexicographically by descending post count and then by
  # ascending alphabetical order.
  for k in sort(collect(keys(TAG_COUNT)), by=x->(-length(TAG_COUNT[x]), x))[1:(min(length(keys(TAG_COUNT)), 5))]
    markdown *= "* ["*k*"](" * Franklin.joinpath("/tag/", k) * ") (" * string(length(TAG_COUNT[k])) * ")\n"
  end
  return fd2html(markdown, internal=true)
end