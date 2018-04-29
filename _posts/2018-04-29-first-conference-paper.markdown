---
layout: post
title:  "First Conference Paper"
date:   2018-04-29 12:50:00 +0900
categories: papers cs automata
---
My first conference paper entitled "Online Stochastic Pattern Matching" was accepted to CIAA'18. This paper was written with my advisor, Dr. Yo-Sub Han.

In this paper, we extend a well known pattern matching problem where one is given a regular expression and a large text and wants to locate all matching substrings. Instead of a regular expression, we have a stochastic language modelled by a probabilistic finite automaton. We wish to find all substrings of a text that have probability greater than some threshold probability $p$.

We describe a method to solve this problem even when the text is given as a stream of characters and we are allowed some constant sized buffer (in the size of the text). This is possible as the length of the longest string with probability at least $p$ depends only on the distribution and not the size of the text. We describe a new upper bound on the longest string with probability at least $p$ that is several orders of magnitude better than the previously best known bounds in practice. We also provide several heuristics for further speeding up the problem and discuss an asymptotically faster algorithm when the stochastic language is modelled by a deterministic probabilistic finite automaton.

[A draft of the paper can be found here.]({{ "/assets/pdfs/ciaa_ospm.pdf" | absolute_url }})