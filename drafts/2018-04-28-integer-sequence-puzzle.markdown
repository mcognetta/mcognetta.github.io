---
layout: post
title: Puzzle
date: 2018-04-23 18:00.000000000 +09:00
---

The following problem was posed to me by a friend:

Given a number $$N > 1$$ print out all sequences that begin with 0 and end at $$ N $$ where the difference between any two adjacent terms in a sequence is a non-negative power of 2.

For example, the possible sequences for $N = 4$ are:
<ul>
	<li>0, 1, 2, 3, 4</li>
	<li>0, 1, 2, 4</li>
	<li>0, 1, 3, 4</li>
	<li>0, 2, 3, 4</li>
	<li>0, 2, 4</li>
	<li>0, 4</li>
</ul>
This is the time where you should stop and see if you can come up with a solution.<!--more-->

The first approach you might consider is to just brute force it but this will definitely lead to a suboptimal solution.

Instead, a recursive approach can be used. The first thing to note is that every sequence begins with $$ 0$$ and is non-decreasing, so we can effectively disregard this term. The next key step comes from the following question: suppose you are finding the solutions for some $$ N$$ and you have already calculated a valid sequence up to $$ m<N$$. How many valid sequences are possible given that you have already reached $$ m$$?

In fact, it is exactly the number of sequences that start at $$ 0$$ and go up to $N-m$ under the same conditions as before. This means, if we have already computed all of the sequences for each value $$ 1 \le n \le N$$, we can simply append the appropriate set of sequences to our current one after removing the $$ 0$$ term and performing an offset calculation. For the offset, we increment each term in the sequence by $$ m$$.

Here is a worked example:

Suppose we want to know all of the solutions for $$ N=7$$ and we have reached the point in the computation where we have generated the sequence $$ 0, 1, 3$$. Now we need to get from $$ 3$$ to $$ 7$$ with the difference between each pair of consecutive terms being a power of $$ 2$$.  The possible sequences are:
<ul>
	<li>0, 1, 3, 4, 5, 6, 7</li>
	<li>0, 1, 3, 4, 5, 7</li>
	<li>0, 1, 3, 4, 6, 7</li>
	<li>0, 1, 3, 5, 6, 7</li>
	<li>0, 1, 3, 5, 7</li>
	<li>0, 1, 3, 7</li>
</ul>
which correspond exactly to the sequences that we found for the example of $$ N = 4$$. For example, the sequence 0, 1, 3, 5, 7 is constructed by taking the sequence 0, 2, 4, removing the 0, and offsetting it by 3 before appending it to the already constructed sequence 0, 1, 3.

Now we only need to know how to generate the initial sequences and then we can recursively solve this problem. Each sequence must start with 0, so the next number has to be a power of 2. Thus, we can just generate all of the sequences $$ [0, 2^i]$$ where $$ 2^i \leq N$$ and then recursively solve the problem.

Here is a snippet of Python code that solves the problem recursively:

{% highlight python %}
def rec(N):
    if N < 1:
        return [[]]
    else:
        i=0
        result = []
        while 2**i <= N:
            for temp in rec(N-2**i):
                new = [0,2**i]+[2**i+x for x in temp[1:]]
                result.append(new)
            i+=1
        return result
{% endhighlight %}

 

Unfortunately, this will run into a common problem with recursive algorithms. If I  compute the answer for the subproblem $$ N = 5$$ and need it again later, I have to compute it all over again since it is never stored. There are several ways of solving this problem (namely caching), so here we will present a dynamic programming solution.

Instead of recursively calling our procedure every time we need the answer to a subproblem, we can iteratively build up all of the subproblems from 1 to $$ N$$ and call them as necessary.

So, given $$ N $$, we construct all solutions for $$ N=1, 2, \dots, N $$ in order, and whenever we need to use a previously computed answer, we simply look it up in some table.

{% highlight python %}
def dp(N):
    table = [[[0]],[[0,1]]]
    for k in range(2,N+1):
        i=0
        out = []
        while 2**i <= k:
            if k-2**i < 1:
                row = [[]]
            else:
                row = table[k-(2**i)]
            for seq in row:
                new = [0,2**i]+[2**i+x for x in seq[1:]]
                out.append(new)
            i+=1
        table.append(out)
    return table[-1]
{% endhighlight %}

We can verify our results by checking the length of the output for $$ N$$ matches $$ a_N$$ in <a href="https://oeis.org/A023359" target="_blank">A023359</a> from the OEIS.