@def title = "Rewriting the Site in Franklin.jl"
@def date = "09/26/2020"
@def tags = ["meta"]
 
# Rewriting the Site in Franklin.jl
 
I am a big fan of the Julia language and enjoy contributing to and making use of its growing ecosystem. I originally wrote this site using Hugo (actually, I probably did it in something else first, this is the `n`th iteration), but there were things that I wanted to do that were difficult and the writing/deployment process was hard to remember if I took even a short break.
 
I decided recently to switch to [Franklin.jl](https://github.com/tlienart/Franklin.jl), a nice static-site generator written in Julia. I was initially on the fence as it is not as popular as other static-site generators, so I cannot be sure of its longevity. I decided to just go for it when an issue that I posted about was solved[^1].
 
I particularly enjoy the flexibility granted by it allowing arbitrary Julia code to be defined and executed during the generation process[^2]. I have some features I wish to add to my site (in particular, I wish to have quick and easy markdown file transclusion, which is not supported in vanilla markdown or by many of the major static-site generators) and I find this should be possible using Franklin.
 
[^1]: [https://github.com/tlienart/Franklin.jl/issues/582](https://github.com/tlienart/Franklin.jl/issues/582)
[^2]: [https://franklinjl.org/syntax/utils/](https://franklinjl.org/syntax/utils/)