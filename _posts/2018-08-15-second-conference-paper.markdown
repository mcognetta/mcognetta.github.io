---
layout: post
title:  "Second Conference Paper"
date:   2018-11-01 12:50:00 +0900
categories: 
 - papers
 - cs
 - automata
---
My second conference paper, entitled "Incremental Computation of Infix Probabilities for Probabilistic Finite Automata", was accepted to EMNLP and I traveled to Brussels last week to present it. This was written with my advisor, Dr. Yo-Sub Han,
and an undergraduate intern (who now works for Google Korea), Soon Chan Kwon. In it, we solve an open problem of incrementally computing infix probabilities in PFAs. That is, suppose you are given some string $w = w_1w_2\ldots w_n$ and a PFA $\mathcal{P}$ and you want to know the infix probability of each prefix of $w$, is there a faster way then just some naive infix probability calculation on each of the prefixes individually? In other words, is there a way to use the infix probability calculation of $w_1w_2\ldots w_k$ to speed up the computation of the infix probability of $w_1w_2\ldots w_kw_{k+1}$?

The naive method involved computing a DFA for the language of all strings with $w$ as an infix (this can be done using KMP in linear time to the string length),
 intersecting it with the PFA, and computing the weight of all strings in the intersection. For a string $w$ and a PFA with $|Q|$ states, this approach takes 
$O(|w||Q|)^m)$ time, where $m$ is the optimal matrix multiplication constant. To get the infix probabilities of all prefixes of $w$, this approach can be used to get an $O(|w|(|w||Q|)^m)$ time algorithm.

We describe a procedure that converts regular expressions into matrix calculations on the transition matrices of a PFA. Using this and a state elimination technique,
 we find an algorithm that (using dynamic programming) generates transition matrices that evaluate to the infix probability of the current infix being considered. 
 This approach takes $O(|w|^3 |Q|^m)$ time, which is asymptotically faster than the previous best time.

There are still several open problems, namely finding an incremental method when the PFA is replaced with a Probabilistic Context Free Grammar or doing this 
incremental algorithm in an online manner (where we do not know all of $w$ ahead of time and instead receive it character by character).

The paper can be found [here](http://aclweb.org/anthology/D18-1293) and the poster can be found [here]({{ "/assets/pdfs/emnlpposter.pdf" | absolute_url }}).