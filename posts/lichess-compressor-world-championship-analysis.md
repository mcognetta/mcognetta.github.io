@def title = "The Lichess Game Compressor's Analysis of Game 1 of the World Championships"
@def date = "12/13/2024"
@def tags = ["chess", "lichess"]
@def rss_description = "The 2024 Chess World Championships are in the books. The scores, grandmaster commentary, and Stockfish evaluations tell most of the story, but isn't there someone you forgot to ask?"
@def image = "/assets/lichess-compressor-championship-post/gukesh_ding_game_one_cropped.png"
@def rss_pubdate = Date(2024, 12, 13)

# The Lichess Game Compressor's Analysis of Game 1 of the World Championships

![gukesh and ding with the game one stats](/assets/lichess-compressor-championship-post/gukesh_ding_game_one_cropped.png)

~~~
<center><i>
The 2024 Chess World Championships are in the books. The scores, grandmaster commentary, and Stockfish evaluations tell most of the story, but isn't there someone you forgot to ask? 
<br>
<br>
That's right, the <a href="https://lichess.org/">Lichess</a> chess <a href="https://lichess.org/@/lichess/blog/developer-update-275-improved-game-compression/Wqa7GiAA">game compression model</a> has some key insights for us.
</i></center>
<br><br>
~~~


**Note**: This post can also be found on [Lichess](https://lichess.org/@/fruitdealer2002/blog/the-lichess-game-compressors-analysis-of-game-1/X0afKqm2) and [Bluesky](https://bsky.app/profile/mcognetta.bsky.social/post/3lbuj5fz3gs2x).

~~~
<small><small>
<b>Note 2</b>: This post is satirical. I mean the numbers and stuff are real and actually drawn from the compressor, but the commentary is not.
</small></small>
<br>
<br>
~~~


Trained on millions of games, the Lichess compression model converts moves to bits depending on how good they are. Pretty sure it can give Stockfish a run for its money. Let's see how accurate Gukesh and Ding were in game 1.


![the rank of each move in the game according to the compressor for each player](/assets/lichess-compressor-championship-post/game_one_index.png)


Gukesh agreed with the Lichess Compressor's best move 6 times out of 42. Ding, on the other hand, agreed just twice. A sad showing. On average, they both chose the ~11th best moves with medians of 10.5 and 8, respectively. Is this what you would expect from potential World Champions?



In particular, the Lichess compressor noted one massive blunder by Ding: 18. ... Nb2??. This is the 47th best move out of 49 available moves in the position. Insanity. The Lichess compressor recommends the far better Nxe5!!.


![the blunder 18. .. Nb2??](/assets/lichess-compressor-championship-post/nb2.png)

From an entropy standpoint, we see a clear difference in play. The Lichess compressor uses an average of ~4.4 bits per move for encoding. Gukesh and Ding required an average of 4.98 and 5.21 bits, respectively, indicating that they deviated significantly from established thought.



![the number of bits required to encode each move in the game according to the compressor for each player](/assets/lichess-compressor-championship-post/game_one_bits.png)


Gukesh required 209 bits to encode his moves while Ding required a whopping 219! Of that, an enormous 14 bits were needed for his catastrophic Nb2?? blunder. That's more than 6% of the encoding!

We should all pray for Lichess and whoever is covering their storage costs if this is the future of chess.

On an unrelated note, I once made a Lichess bot that used the compression function as an evaluation function. It didn't win a single game.

# Appendix

If you are interested in producing your own graphs like the ones in this article, here is a [Colab](https://colab.research.google.com/drive/1H9cw_o-e3aLgKpwcfzzI3P4l8tkgkhPR?usp=sharing) that can convert a PGN input or a Lichess game into a graph.