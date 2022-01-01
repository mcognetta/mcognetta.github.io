@def title = "Solving (and Animating) Advent of Code Day 1 with 아희"
@def date = "12/29/2021"
@def tags = ["aheui", "manim", "python", "아희"]

@def rss_pubdate = Date(2021, 12, 29)

# Solving (and Animating) Advent of Code Day 1 with 아희

*The original Korean version of this post can be found [here](https://mcognetta.github.io/posts/aoc-aheui-kr/), or see it on [Twitter](https://twitter.com/good_in_theory/status/1477073821693886469).*

The [2021 Advent of Code](https://adventofcode.com/) challenge has just ended. Typically, I do the problems in Python or Julia (or, this year, some in Dart), but this time I also solved the first day’s problem using [아희 (Aheui)](https://esolangs.org/wiki/Aheui), a Korean esoteric programming language. On top of this, I hooked up my [아희 interpreter](https://github.com/mcognetta/aheuiPython) to the [Manim animation library](https://www.manim.community/) to generate animations that show the internal state of the 아희 program as it executes!

~~~
<video controls autoplay muted>
  <source type="video/mp4" src="/assets/aheui-aoc-post/p1_en.mp4">
</video>
~~~

### 아희 Crash Course

To understand the rest of this post, one should first be familiar with 아희. There is a complete [English specification](https://aheui.readthedocs.io/ko/latest/specs.en.html), but here I will introduce the main themes of the language.

아희 is written as a 2-dimensional grid of Korean characters. Each Korean character encodes an instruction (`add`, `subtract`, `push`, `swap`, etc), a direction, and possibly some parameters for the function.

For example, here is a program that outputs `Hello, world!`:

```
밤밣따빠밣밟따뿌
빠맣파빨받밤뚜뭏
돋밬탕빠맣붏두붇
볻뫃박발뚷투뭏붖
뫃도뫃희멓뭏뭏붘
뫃봌토범더벌뿌뚜
뽑뽀멓멓더벓뻐뚠
뽀덩벐멓뻐덕더벅
```

Korean characters are made up of three parts, the initial consonant, a vowel, and an (optional) final consonant. For example, `한` is `ㅎ/ㅏ/ㄴ` and `가` is `ㄱ/ㅏ` (with no final consonant). When reading a character, the top or top-left section is the initial consonant. The middle/middle-right/right is the vowel, and the bottom is the final consonant. A visual introduction can be found [here](http://easykorean.edsoftapps.com/learn-structure-of-hangul/).

In 아희, the initial consonant determines the instruction. A full list of these can be found in the specification, but later on I will provide a list of the relevant ones for this post.

The directional information is provided by the vowel. As you execute an 아희 program, you traverse the grid with some momentum. When you execute a command, the vowel tells you how to update your momentum, and then you can determine the next cell. Conveniently, the vowel/direction mappings are determined by the shape of the vowel. For example, `ㅏ` means “your new momentum is right with magnitude 1”. Likewise, `ㅜ` would give a downwards momentum with magnitude 1. Vowels like `ㅑ/ㅕ/ㅛ/ㅠ` are the same but with magnitude 2. Other vowels reflect the momentum, and some have no effect. One other key feature is that, if an instruction fails (for example, if the instruction is `add`, but an invalid parameter is passed), the momentum information is reflected (so that `ㅏ` would act as `ㅓ`).

The final consonant acts as a parameter to some instructions and has no effect on others. Depending on the instruction, the final consonant can act as a pointer to select certain things (mainly data structures), or it can act as some numerical consonant. In the chart of instructions below, the effect of the final consonant is given.

An 아희 program has access to several data structures: 26 stacks, 1 queue, and 1 undefined extension protocol. Each data structure is mapped to one final consonant so that they can be easily indexed. At any time during the execution of a program, there is one “active” data structure, upon which instructions can act. The `ㅅ` command allows one to select a new active data structure.

아희 programs begin at the top left of the 2-d code grid, and execute continuously until a cell with the instruction `ㅎ` is reached, which immediately terminates the program.

#### A Slight Modification to the 아희 Specification

아희 allows for reading from user input (via the `ㅂ`-push instruction with a `ㅇ` or `ㅎ` final-consonant parameter). However, this does not necessarily cover reading from a piped in file (which is required here, as Advent of Code inputs are given as text files). I slightly deviated from the specification in my interpreter to make the `ㅂ`-push instruction read from an input file, with the condition that, if a read is performed after the end-of-file had been reached, it would count as a failed instruction (and so the direction information would be reversed, as explained above).

### Advent of Code Day 1 Solution

This year, the [first day's problem](https://adventofcode.com/2021/day/1) was roughly: “in a list of numbers, how many times is a number immediately followed by a larger number?” For example, if the list was `1, 4, 2, 5, 7` , then the pairs `1->4, 2->5, 5->7` means the correct answer must be `3`.

In Python, a possible solution is:

```python
if __name__ == '__main__':
    f = open('input.txt', 'r')
    x = int(f.readline())
    count = 0
    for line in f:
        y = int(line)
        if y > x: count += 1
        x = y
    print(count)
```

In 아희, I solved it in the following way:

```
삼바샇뱡숨방파빠파주
마르코하멍솧더섬썸퍼
```

There are several instructions used in this program (listed here in Korean alphabetical order):

*  `ㄷ` -> add
   *  From the active data structure, pop the top two values, add them, and push them back to the data structure.
   *  The final consonant has no effect.
*  `ㅅ` -> select a data structure
   * Select a new active data structure.
   * The final consonant specifies the data structure to select.
   * In this program, we use:
     * `ㅁ` -> queue
     * `ㅇ` -> a stack
*  `ㅂ` -> push an item to the active data structure
   *  If the final consonant is `ㅇ`, read from the input file and push the value.
   *  If there is no final consonant, push a `0`.
   *  Otherwise, (except for `ㅎ`) push an integer based on the number of lines in the final consonant.
      *  `ㄱ -> 2`
      *  `ㅃ -> 8`
*  `ㅍ` -> swap
   * Swap the top two values in the active data structure.
     * Note that this does not pop and then push, but swaps them in-place.
   * The final consonant has no effect.
*  `ㅃ` -> duplicate
   * Copy the top value of the active data structure and push it.
   * The final consonant has no effect.
*  `ㅈ` -> compare
   * Pop the top two values of the current data structure, compare them, and push `0` or `1` depending on the result.
   * The final consonant has no effect.
*  `ㅆ` -> transfer
   * Pop the top value of the active data structure and push it to the data structure indexed by the final consonant.
*  `ㅁ` -> print
   * Pop the top value of the active data structure, and print the result.
   * If the final consonant is `ㅇ`, print it as an integer.
   * If the final consonant is `ㅎ`, print the Unicode character corresponding to the value.
*  `ㅎ` -> terminate
   * Immediately end the program. 
   * The final consonant has no effect.

\

```
삼바상뱡숨방파빠파주
마르코하멍송더섬썸퍼
```

My solution contains 4 parts. The first part is the top left corner `삼바상뱡`, which is intended to initialize the program. The `ㅁ`-stack will hold a counter, and so we initialize it with zero via `삼바` (select `ㅁ`-stack, push `0`). The `ㅇ`-queue will process each element from the input file as it comes in, so we initialize it with the first value in the file via `상뱡` (select `ㅇ`-queue, read stdin). Notice that `뱡` has momentum 2, so when it successfully runs, the next cell will be two to the right, `방`, not `숨`.

The second part is the main logic:

```
방파빠파주
송더섬썸퍼
```

Notice that the vowels here form a cycle: `방 -> 파 -> 빠 -> 파 -> 주 -> 퍼 -> 썸 -> 섬 -> 더 -> 송 -> 방 -> ...`. This cycle is designed to repeat until the `방` instruction fails (meaning that the end-of-file has been reached).

At the start of this cycle, the active data structure is the `ㅇ`-queue, which contains one element, the first number in the file. This cycle performs the following actions:

- Read a number and push it to the queue (`방`).
  - The queue is now `[new, old]`.

- Swap the new and old numbers (so the new one is at the front) (`파`).
  - The queue is now `[old, new]`.

- Duplicate the new number (and push it to the queue) (`빠`).
  - The queue is now `[new, old, new]`.
  - This is in preparation for the next iteration of the cycle, when the just-read “new” number is the “old” number.

- Restore the original order of the old and new numbers (`파`).
  - The queue is now `[new, new, old]`.

- Compare the old and new numbers (and push the result to the queue) (`주`).
  - The queue is now  `[result, new]`.

- Swap the top elements of the queue, so the result is on top (`파`).
  - The queue is now  `[new, result]`.

- Send the result to the counter `ㅁ`-stack (`썸`).
  - The `ㅁ`-stack is now `[count, result]`.
- Make the counter `ㅁ`-stack the active data structure (`섬`).
- Sum the top two elements of the count stack (`더`).
  - The `ㅁ`-stack is now `[counter + result]`.
- Switch to the queue (`송`).

At this point, we are back at the start of the cycle, and can repeat.

When the `방` at the start of the cycle fails (that is, after we have reached the end-of-file), the direction is reversed, and we move to the third section:

```
....숨..
..하멍..
```

Here, we switch to the counter `ㅁ`-stack (`숨`), print the value (`멍`), and terminate (`허`).

The last section, `마르코`, is just my name. It is unreachable, and so it is never executed. I put it there both for flair and to preserve the rectangular shape of the program.

#### Demonstration

The flow of the program can be understood visually. The first animation covers the initialization of the program and several iterations of the main logic cycle.

~~~
<video controls autoplay muted>
  <source type="video/mp4" src="/assets/aheui-aoc-post/p1_en.mp4">
</video>
~~~

The following iteration demonstrates how the program breaks out of the cycle when the end-of-file is reached.

~~~
<video controls autoplay muted>
  <source type="video/mp4" src="/assets/aheui-aoc-post/p1_end_en.mp4">
</video>
~~~

### Day 1, Part 2

The first day's puzzle has a second part, which is a slight variant of the problem above. In this case, rather than comparing each adjacent number, we compare the sum of each successive set of three numbers. For example, if the list was `1, 4, 2, 5, 7`, we would compare `1 + 4 + 2` to `4 + 2 + 5` to see if the second sum was bigger.

In Python, one can solve it like so:

```python
if __name__ == '__main__':
    count = 0
    f = open('input.txt', 'r')
    x, y, z = int(f.readline()), int(f.readline()), int(f.readline())

    for line in f:
        a = int(line)
        if a > x: count += 1
        x, y, z = y, z, a
    print(count)
```

Note that we make use of the fact that `x + y + z < y + z + a` can be determined by checking `x < a`.

I also solved this problem with the following 아희 code:

```
삼바상방방방샨숨방빠쌍상싼산반분
마르코코그넷허멍손더섬썸저어더너
```

\

~~~
<video controls autoplay muted>
  <source type="video/mp4" src="/assets/aheui-aoc-post/p2_en.mp4">
</video>
~~~

\

This again has 4 parts. `삼바상방방방샨` initializes the program. In this program, we have a counter stack (`ㅁ`-stack), a “workspace” stack (`ㄴ`-stack), and a queue (`ㅇ`-queue). The queue will hold the current 3 numbers whose sum we are comparing against, with the oldest number at the front of the queue. We initialize the program by pushing a `0` to the counter `ㅁ`-stack, then reading the first three numbers to the queue, and finally reading the 4th number to the `ㄴ`-stack.

The main logic is again a loop:

```
방빠쌍상싼산반분
손더섬썸저어더너
```

At the start, the active data structure is the `ㄴ`-stack, which holds just the newest number (`x[i]`). The queue holds `[x[i-3], x[i-2], x[i-1]]`. Here, we copy the just-read number and send it to the back of the queue, to prepare for the next iteration. Then, we send the front of the queue (the oldest number in the current set) to the `ㄴ`-stack, so it can be compared with the just-read in number.

In part one, we also had to do a comparison between old and new numbers. The `ㅈ`-compare command acts as a `≥`, but what this question requires is `>`. It turns out that there aren’t cases of `x[i] == x[i-1]` in the input (at least, in my input), but there are many cases of `x[i] == x[i-3]`. This means that we cannot compare the old and new numbers directly with `ㅈ`, as it would over count (when the triplet sums are equal). To avoid this, we add one to the older number, so that `ㅈ` returns `1` only when the new number is strictly larger (that is, `new ≥ old + 1`).

In 아희, there is no way to directly push a `1` into a stack (recall that `ㅂ`-push pushes a value based on the number of lines in the final consonant; since `ㅇ` is already reserved for reading from stdin, there are no available final consonants with only one line). One way to input a one is to push the same value twice and then divide (the `ㄴ` command). This is done with `반/분/너`, which pushes a `2` twice and then divides, leaving `1`. Once the addition and comparison are done, the counter is updated and the loop starts over (so that now, the queue holds `[x[i-2], x[i-1], x[i]]` and the `ㄴ`-stack holds `[x[i+1]]`).

In addition to `ㄴ`-divide, one other new instruction is present in this program, `ㅇ` (seen in the `어` character). This is the "no op" instruction, and it does nothing (but the vowel can still have an effect). It is typically used to preserve the layout of the program, or for program flow. Here we use it to preserve the rectangular structure of the loop.

Exactly like the first problem, when the end-of-file is reached, the beginning of the loop `방` instruction fails, sending the program to the third section:

```
....숨...
..허멍..
```

which prints the counter value and terminates.

Again, the fourth section: `마르코코그넷허` is my name. Unfortunately, this is not how I typically spell my name. The correct version, `마르코 코그넷*터*` would not fit while preserving the rectangular shape, so I combined the `넷터` and terminating `허` into `넷허`, which has a similar pronunciation.