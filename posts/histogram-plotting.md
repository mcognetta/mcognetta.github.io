@def title = "Multiple Histograms and a Line Graph in One Figure with Seaborn/Matplotlib"
@def date = "01/09/2023"
@def tags = ["plotting", "python", "TIL"]
 
@def rss_description = "A quick TIL about plotting a graph with a sequence of histograms and a summary-statistic line graph in one figure."
@def rss_pubdate = Date(2023, 01, 09)

# Multiple Histograms and a Line Graph in One Figure with Seaborn/Matplotlib

I recently had to plot a graph that was supposed to look something like this[^1] :

![example_graph](/assets/seaborn-post/example_graph.png)

In short, I had some histograms that changed each year and I wanted to show the changes side-by-side as well as a summary statistic (e.g., mean). For this example, I had a list of datapoints that had a "year" feature and four "category" features (0, 1, 2, 3), each with a count. I wanted to plot both the histogram of "number of category X" per year as well as the mean summary statistic of the counts as a line graph overlayed above the histograms.

Matplotlib and Seaborn didn't seem to have a clear way to do this out-of-the-box, but I was able to find a way around it, which resulted in the following layout:

![seaborn_graph](/assets/seaborn-post/seaborn_graph.png)

This was pretty close to what I originally intended. The line graph being laid directly over the histograms is a little different, but could be changed by relabling the right side y-axis. Also, the "category" label doesn't appear under each histogram bar, but in a single, color-coded legend, which I think looks nice.

## Minimal Working Example

~~~
<script src="https://gist.github.com/mcognetta/4183d687ba9fea2ba70b96970c6b0695.js"></script>
~~~

[^1]: Drawn with [Excalidraw](https://excalidraw.com/).