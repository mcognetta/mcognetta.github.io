@def title = "Masked Softmax Layers in PyTorch"
@def date = "10/25/2025"
@def tags = ["math", "ml"]

@def rss_description = "Correctly computing masked softmax layers."
@def rss_pubdate = Date(2025, 10, 25)


# Masked Softmax Layers in PyTorch

Neural classification models typically have a *softmax* layer as the last step of their model, which turns unnormalized log probabilities (logits) that are produced by the model into a normalized probability distribution over the output classes. Let $\ell$ be a vector of dimension $n$ (the number of classes), where $\ell_i$ represents the logit for class $i$. Then, for a given class $i$, softmax computes the probability:
$$
p_i = softmax(\ell)_i = \frac{e^{\ell_i}}{\sum_{j}^ne^{\ell_j}}
$$
In PyTorch, this is implemented as:

```python
import torch
ell = torch.normal(0., 1., size=(5,)) # -> [1.2355, -0.1710, -0.6606, -0.2050, -1.4690]
torch.softmax(ell, dim = 0)           # -> [0.5886, 0.1442, 0.0884, 0.1394, 0.0394]
```

However, a side effect of this is that neural models can't produce zero probabilities since that would require outputting $-\infty$ as a logit, even though we often have some structural knowledge about the input that tells us some of the outputs are invalid and should be given probability zero. In this case,  we only want to accumulate exponentiated logits for valid classes:
$$
p'_i = \frac{e^{\ell_i}\delta_i}{\sum_j^n e^{\ell_j}\delta_j}
$$
where $\delta_i$ is an indicator function determining if class $i$ is valid.[^1] 

For example, suppose we have the following setup: we have logits $\ell$ and a mask, where $\texttt{mask}[i]$ is True/False depending on if class $i$ is valid and acts as our indicator function $\delta$.

```python
ell = torch.normal(0., 1., size=(5,)) # -> [1.2355, -0.1710, -0.6606, -0.2050, -1.4690]
mask = torch.rand(5) < 0.6            # -> [True, False,  True,  True, False]
```

How can we compute the masked out probability, which should be $[0.7210, 0.0, 0.1083, 0.1707, 0.0]$ in our example? The first class probability is found via:
$$
\frac{e^{1.2355}}{e^{1.2355} + e^{-0.6606} + e^{-0.2050}} = 0.721
$$


I recently came across an example that tried to compute what we wanted like:

```python
torch.softmax(ell * mask, dim = 0) # -> [0.5080, 0.1477, 0.0763, 0.1203, 0.1477]
```

But, this is incorrect (the invalid classes don't have probability 0). Can you spot why?

The issue is that the invalid logits are *multiplied* by 0 ($\texttt{False}$), which becomes $e^0 = 1$ during softmax. Instead, we want the probability to be 0 *after* softmax, which means we need to replace the logits with $-\infty$, since $e^{-\infty} = 0$. In the above implementation, all invalid logits get (the same) non-zero probability after normalization and valid classes get incorrect probabilities, since the invalid classes contribute to the softmax denominator.

In the pessimal case, the invalid logits can actually have the highest probability after softmax and in more normal cases, they can still siphon away a lot of probability mass from valid classes. While the first case is probably rare in practice, the second case is particularly bad in that predicting an invalid class is the worst thing you can do in such a classification problem. If there are enough invalid classes and the (unmasked) probability of the valid classes is low, the sum of the invalid class probabilities might be the highest and so sampling from the output distribution has a high chance of returning an invalid output.

## Correct Implementations

Here are two correct ways to implement masked softmax.[^2] The first performs unmasked softmax and then renormalizes:

```python
probs = torch.softmax(ell, dim = 0)          # -> [0.5886, 0.1442, 0.0884, 0.1394, 0.0394]
masked_out = probs * mask                    # -> [0.5886, 0.0000, 0.0884, 0.1394, 0.0000]
masked_probs = masked_out / masked_out.sum() # -> [0.7210, 0.0000, 0.1083, 0.1707, 0.0000]
```

The second uses the correct masking at the logit level by adding $-\infty$ to invalid logits. One trick is to note that $\texttt{False}$ can be interpreted as 0, and $\ln 0 = -\infty$, so the `log` of the mask can be added to the logits:[^3]

```python
masked_probs = torch.softmax(ell + mask.log(), dim = 0) # -> [0.7210, 0.0000, 0.1083, 0.1707, 0.0000]
```

These two approaches are equivalent. Let $x, y, z$ be logit values and suppose we have a mask that says that $x$ and $y$ are valid and $z$ should be masked out.

Then, the first approach first computes: 

$$
p_x = \frac{e^x}{e^x + e^y + e^z},~~p_y = \frac{e^y}{e^x + e^y + e^z},~~p_z = \frac{e^z}{e^x + e^y + e^z}
$$
When we mask out $p_z$, the sum $p_x + p_y + 0 \le 1$, so we need to renormalize with the sum of the unmasked probabilities $p_x + p_y$. Now, the new probabilities are:


$$
p'_x = \frac{p_x}{p_x + p_y} = \frac{\frac{e^x}{e^x + e^y + e^z}}{\frac{e^x}{e^x + e^y + e^z} + \frac{e^y}{e^x + e^y + e^z}} = \frac{\frac{e^x}{e^x + e^y + e^z}}{\frac{e^x + e^y}{e^x + e^y + e^z}} = \frac{e^x}{e^x + e^y},
$$
and likewise for $p'_y$ , as desired.

On the other hand, the second approach manipulates the logits before the softmax by adding $-\infty$ to invalid class logits, so we compute:
$$
p'_x = \frac{e^x}{e^x + e^y + e^{z + -\infty}} = \frac{e^x}{e^x + e^y + e^{-\infty}} = \frac{e^x}{e^x + e^y},
$$
and get the desired result directly.

The `+ mask.log()` approach has an added benefit of requiring fewer passes over the data, which provides a modest speedup on GPUs.

### An Aside: Masked Indexing
Another approach could be to gather just the valid logits and then perform softmax like `torch.softmax(logits[mask], ...)`. This is not ideal for two reasons. First, you have to track the original positions of the gathered indices so that you can recover the valid class probabilities. And second, indexing like this doesn't preserve shape, so this method becomes tricky with batched inputs (especially where the number of masked classes per row is different).[^4][^5]

## Real-Life Example
To contextualize the bug that I found, the problem was [chess move prediction in Maia2](https://github.com/CSSLab/maia2/pull/9), a neural chess engine designed to mimic human play. The input is a board, and the output is a probability distribution over moves. The set of possible moves is highly dependent on the position and it is difficult to encode variable-sized outputs in neural models, so the authors of Maia2 opted to have an output layer that encodes all possible moves on _any_ board.[^6] That is, even if the move $\texttt{c4c5}$ isn't a valid move for your input, it is still allocated a logit. On the other hand, the move $\texttt{b1c6}$ does not have a logit associated with it, since that move is not possible in any board configuration. In total, there are ~1900 moves in their output layer. 

However, the number of chess moves in any specific position is much smaller than this. In fact, it was recently shown that [there is no legal position with more than 218 possible moves](https://lichess.org/@/Tobs40/blog/why-a-reachable-position-can-have-at-most-218-playable-moves/a5xdxeqs). So, when running inference, Maia2 tries to mask out the probability of invalid moves but the incorrect masking leads to them still being assigned non-zero probability mass. In most cases, it is fairly small (less than $0.1\%$ total) but in the Maia2 repo's example test set of ~100k positions, the worst case was that $5.1\%$ of the total probability mass was leaked to invalid moves. In other words, if we randomly sampled a move from this distribution, more than 1 in 20 samples would be for a move that can't even be played!

-------------------------------

[^1]: We assume that *some* class is considered valid, otherwise we would have a degenerate case where all classes should be given probability 0.
[^2]: If the input is a *batch* of logits, you need to use `masked_out.sum(dim = -1, keepdim = True)`to correctly collect and broadcast the normalization constant. The `mask.log()` approach does not require any modifications to work with batched inputs.
[^3]: One could also use `torch.where(mask, 0, float("-inf"))` to produce the same output as `mask.log()`.
[^4]: For example, `torch.rand((3, 5))` and `torch.rand((3, 5)) < 0.1` both have shape `(3, 5)` and `ndim = 2`, but `torch.rand((3, 5))[torch.rand((3, 5)) < 0.1]` has `ndim = 1` and a shape that is determined at runtime.
[^5]: Some tensor frameworks have support for "ragged tensors", which don't require a rectangular shape (e.g., [PyTorch Nested Tensors](https://docs.pytorch.org/docs/stable/nested.html) and [TensorFlow Ragged Tensors](https://www.tensorflow.org/guide/ragged_tensor)), but in my experience, it is much better to try to work with rectangular tensors unless you absolutely cannot implement what you need with them. The correct softmax operations in this article all preserve shape throughout the computation and are easy to scale to sizes/batches/etc.
[^6]: Maia2 makes a simplifying transformation by remapping all input boards to be as if it was white's turn to play (by flipping the board and the piece colors if the actual position is black's turn). This slightly reduces the number of possible moves for the output layer and makes the model robust to the side-to-move. 