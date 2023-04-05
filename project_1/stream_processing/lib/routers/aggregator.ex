defmodule Aggregator do
# TODO All Workers now route to aggregator
# TODO When receiving a tweet part, aggregator checks if it 'got em all'. On a yes it removes the tweet from memory and forwards it to the batcher.
# TODO On a no, it updates the tweet part in the memory or creates a new one.

# TODO Implement Reactive Pull, instead of pushing everything into the batcher. If aggregator can, it sends tweet to batcher. If it can't, change state and immediately send the next completed tweet to batcher.
end
