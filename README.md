# EfficientJoin

Very fast and memory-efficient way to join ruby lists of numbers and strings.

Joins are performed with a constant number of ruby object allocations,
compared to `Array#join`, `PG:TextEncoder::Array.new.encode`, etc, where at least `n` object
allocations are required to join an array of `n` items.

For tests with array sizes of 1 million entries, here are some measured memory
usage and execution time improvements:

| EfficientJoin function | Equivalent ruby function          | Memory usage | Time         |
| ---------------------- | --------------------------------- | ------------ | ------------ |
| join                   | Array#join                        | 30%          | 7.0x faster  |
| join_pg_array          | PG::TextEncoder::Array.new.encode | 18%          | 7.4x faster  |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'efficient_join'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install efficient_join

## Usage

With ruby #join:

```
MemoryProfiler.report { (0...1000000).to_a.join(',') }
  ...
  @total_allocated=1000003,
  @total_allocated_memsize=62636393,
```

With efficient join:
```
require 'efficient_join'
EfficientJoin.join((0...1000000).to_a)
  ...
  @total_allocated=5,
  @total_allocated_memsize=18525362
```

It can also take separator, item prefix and item suffix:
```
EfficientJoin.join([1,2,3,4], separator: ',', item_prefix: '(', item_suffix: ',now(),now())')
 => "(1,now(),now()),(2,now(),now()),(3,now(),now()),(4,now(),now())" 
```

And has a variant for efficiently building postgres arrays (which is far more
efficient than `PG::TextEncoder::Array.new.encode`:

```
EfficientJoin.join_pg_array([1,2,3,4])
 => "{1,2,3,4}"
```

Which is equivalent to:

```
EfficientJoin.join([1,2,3,4], header: '{', footer: '}')
 => "{1,2,3,4}"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomm/efficient_join.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
